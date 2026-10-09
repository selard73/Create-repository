# Job 7: phone check of the camera (a play test in the Device Simulator; nothing is edited unless Shannon says so)

Shannon, Oct 9, after today's publish: on the phone "it says my camera is equipped but it does not show at the bottom
of the screen like it did before" / "the camera is not even there". On desktop the camera works (she took a photo today).
We need to know whether the camera VR aim patch (job 6) broke the phone, or whether it is something else.

1. Device Simulator ON (her usual phone preset, 667x375 or similar). Studio in Edit mode first.
2. Play test as the owner (Play, not Run). Wait for the game to load in Porto or go there.
3. Try to equip the camera: from the game's own hotbar at the bottom (ShopClient HOTBAR) and from the backpack.
   Note, with a screen capture of each: is the camera slot in the hotbar at all? does equipping show the
   "Tap to raise the camera" toast? does tapping raise the lens? does the "Postcards wanted" panel appear?
4. Read the Output / client log for every error or warning from CameraClient, ShopClient, StowServer, or anything
   mentioning "Camera". Copy the first error in full (message + script + line).
5. Stop the play test. Make sure Studio is back in Edit mode and the Device Simulator is set back how it was.
6. Send ONE message to the cloud session "GitHub free credit eligibility": the answers to step 3, the errors from
   step 4 (verbatim), and the capture paths.
7. ONLY IF CameraClient throws an error at load or on equip: tell Shannon, and with her yes restore the script
   (CameraClient.Source = ServerStorage.HudBackup.CameraClient_v3_pre_vraim.Source), repeat steps 2-5, and send
   the result as well. Do not publish.
