package eraser

import (
	"context"
	"fmt"
	"maps"
	"slices"
	"time"

	"github.com/gotd/td/telegram/query"
	"github.com/gotd/td/telegram/query/messages"
	"github.com/gotd/td/tg"
)

const deleteBatchSize = 100

type msgRef struct {
	id        int
	isService bool
}

func (e *Eraser) deleteMessagesFromEntities(ctx context.Context) error {
	var maxDate int
	if e.cfg.OlderThan > 0 {
		maxDate = int(time.Now().UTC().Add(-time.Duration(e.cfg.OlderThan) * time.Second).Unix())
	}

	for _, ent := range e.entities {
		if ent.peerType == "user" && e.cfg.DeleteConversation {
			if err := e.deleteConversation(ctx, ent); err != nil {
				return err
			}
			continue
		}

		printHeader(fmt.Sprintf("Getting messages from '%s'...", ent.displayName))
		msgs, err := e.getMessagesToDelete(ctx, ent, maxDate)
		if err != nil {
			return fmt.Errorf("failed to get messages from %q: %w", ent.displayName, err)
		}

		if len(msgs) == 0 {
			fmt.Println("\nNothing to delete.")
			continue
		}

		ids := make([]int, len(msgs))
		var service int
		for i, m := range msgs {
			ids[i] = m.id
			if m.isService {
				service++
			}
		}
		fmt.Printf("\nFound %d messages (%d regular, %d service).\n", len(msgs), len(msgs)-service, service)
		if service > 0 && ent.peerType != "user" {
			fmt.Println("Note: service messages may not delete without admin rights; Telegram silently skips unauthorized deletions.")
		}

		if err := e.deleteMessages(ctx, ent, ids); err != nil {
			return fmt.Errorf("failed to delete messages from %q: %w", ent.displayName, err)
		}
	}
	return nil
}

func (e *Eraser) deleteConversation(ctx context.Context, ent entity) error {
	printHeader(fmt.Sprintf("Deleting entire conversation with user '%s'...", ent.displayName))

	for {
		req := &tg.MessagesDeleteHistoryRequest{
			Peer:  ent.peer,
			MaxID: 0,
		}
		req.SetRevoke(true)

		result, err := e.api.MessagesDeleteHistory(ctx, req)
		if err != nil {
			return fmt.Errorf("failed to delete conversation with %q: %w", ent.displayName, err)
		}
		if result.Offset <= 0 {
			break
		}
	}

	fmt.Printf("\nDeleted entire conversation with user '%s'.\n\n", ent.displayName)
	return nil
}

func (e *Eraser) getMessagesToDelete(ctx context.Context, ent entity, maxDate int) ([]msgRef, error) {
	if len(e.cfg.MediaTypes) == 0 {
		return e.searchMessages(ctx, ent.peer, &tg.InputMessagesFilterEmpty{}, maxDate)
	}

	types := expandMediaTypes(e.cfg.MediaTypes)
	seen := make(map[int]msgRef)
	for _, mediaType := range types {
		filter := mediaFilter(mediaType)
		if filter == nil {
			continue
		}
		fmt.Printf("  Fetching %s...\n", mediaType)
		msgs, err := e.searchMessages(ctx, ent.peer, filter, maxDate)
		if err != nil {
			return nil, err
		}
		for _, m := range msgs {
			seen[m.id] = m
		}
	}

	return slices.Collect(maps.Values(seen)), nil
}

func (e *Eraser) searchMessages(ctx context.Context, peer tg.InputPeerClass, filter tg.MessagesFilterClass, maxDate int) ([]msgRef, error) {
	var all []msgRef

	builder := query.Messages(e.api).Search(peer).
		FromID(&tg.InputPeerSelf{}).
		Filter(filter).
		BatchSize(deleteBatchSize)

	if maxDate > 0 {
		builder = builder.MaxDate(maxDate)
	}

	err := builder.ForEach(ctx, func(_ context.Context, elem messages.Elem) error {
		_, isService := elem.Msg.(*tg.MessageService)
		all = append(all, msgRef{id: elem.Msg.GetID(), isService: isService})
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("message search failed: %w", err)
	}

	e.logger.Debug("fetched messages", "total", len(all))
	return all, nil
}

func (e *Eraser) deleteMessages(ctx context.Context, ent entity, msgIDs []int) error {
	printHeader(fmt.Sprintf("Deleting messages from '%s'...", ent.displayName))

	for i := 0; i < len(msgIDs); i += deleteBatchSize {
		end := min(i+deleteBatchSize, len(msgIDs))
		if _, err := e.sender.To(ent.peer).Revoke().Messages(ctx, msgIDs[i:end]...); err != nil {
			return fmt.Errorf("message deletion failed: %w", err)
		}
	}

	fmt.Printf("\nRequested deletion of %d messages in '%s' entity.\n\n", len(msgIDs), ent.displayName)
	return nil
}
