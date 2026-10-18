# Mayor gift notifications

Creator Hub template created and verified on October 18, 2026:
- Universe: 10766369535
- Name: Mayor thank-you gift ready
- Message ID: 8b33d54a-b560-fb48-8339-bd5cb699d53e
- Body: The mayor has left you {acorns} acorns as thanks for your letter. Your gift is ready!
- Parameter: acorns, stringValue, taken from the recipient's already-published gift.
- No player mentions; the friendship requirement for mentioned users does not apply.

The current GiftsClient already includes ExperienceNotificationService opt-in. Do not duplicate that feature or treat CanPromptOptInAsync=false as proof of a subscription. Recipients must choose to opt in themselves.

## Sending from Studio

The official Roblox Open Cloud package is asset 16584168800 (verified Creator Store creator Roblox). Its V2.UserNotification module was inspected without parenting or executing the imported model. That module uses:

    OpenCloudService:InvokeAsync("v2", "userNotification", {
        user = recipientUserId,
        userNotification = {
            source = {universe = "universes/10766369535"},
            payload = {
                messageId = "8b33d54a-b560-fb48-8339-bd5cb699d53e",
                type = "MOMENT",
                parameters = {acorns = {stringValue = "1000"}},
            },
        },
    })

This call must run on a SERVER, including Studio's Play Server. Edit rejected it before making a request. Server calls reached Roblox with HttpEnabled=false and no new credentials. No OpenCloud package or recurring sender was installed in the game.

OpenCloudService is marked deprecated, despite still being used by the official package and current experience-notification guide. It worked for these explicitly authorized one-time requests on this date. For a future automated service, re-check the supported Open Cloud HTTP API instead of assuming indefinite support.

## Operational rules

- Obtain Shannon's instruction to notify the specific recipients. Creating the template does not authorize a broadcast.
- Verify account IDs, published gift amount/id, and current unclaimed status before saying a gift is ready. Never modify claim receipts or balances.
- Send at most one request per authorized recipient; record the response locally before any retry decision. Do not auto-send every server startup, repeatedly probe subscription status, or schedule repeats.
- HTTP 400 FAILED_PRECONDITION with an explicit not-opted-in message means no delivery. Keep the gift waiting. Do not enable notifications on behalf of a player.
- A successful API acceptance is not proof the recipient saw the notification; Roblox delivery limits still apply.
- This template does not send anything by itself. It does not require a game publication.
- Individual subscription/claim audit results stay in local task evidence, not this public repository.

Creator Hub: https://create.roblox.com/dashboard/creations/experiences/10766369535/notifications
Official guide: https://create.roblox.com/docs/production/promotion/experience-notifications
Modern HTTP guide: https://create.roblox.com/docs/cloud/guides/experience-notifications
