/*
 * P9Probe.x — Launch-time selector-existence probe for the P9 download-fix
 *
 * PURPOSE
 * -------
 * Validates, at every cold launch, that the ObjC class metadata present
 * in the running YT Music binary matches the assumptions of the P9 fix:
 *
 *   fix(download): replace dead playerResponse with contentPlayerResponse
 *
 * WHAT IS TESTED
 * --------------
 * The crash was:
 *   NSInvalidArgumentException:
 *     -[YTPlayerViewController playerResponse]: unrecognized selector
 *
 * The fix repoints every call from the dead selector `playerResponse`
 * (removed in YT Music 9.17.2+) to `contentPlayerResponse` (live in 9.23.4+).
 * Whether this crashes is a pure selector-existence condition — it fires
 * the instant the message is dispatched, independent of login state or
 * whether a track is playing.
 *
 * The probe therefore only uses +instancesRespondToSelector: on real classes,
 * which reads the class's method list in the ObjC runtime. No network, no
 * login, no UI navigation required.
 *
 * The full download chain checked (mirrors Downloading.x exactly):
 *
 *   YTPlayerViewController   .contentPlayerResponse  — THE FIX (must be 1)
 *   YTPlayerViewController   .playerResponse         — THE DEAD SELECTOR (must be 0)
 *   YTPlayerResponse         .playerData             — YTPlayerResponse → YTIPlayerResponse
 *   YTIPlayerResponse        .videoDetails           — inner proto getter
 *   YTIPlayerResponse        .streamingData          — inner proto getter
 *   YTIStreamingData         .hlsManifestURL         — audio stream URL
 *   YTIVideoDetails          .thumbnail              — thumbnail proto getter
 *   YTIThumbnailDetails      .thumbnailsArray        — array of thumb entries
 *
 * PASS CRITERION (all conditions must hold)
 * -----------------------------------------
 *   YTPlayerViewController:  contentPlayerResponse=1  AND  playerResponse=0
 *   YTPlayerResponse:        playerData=1
 *   YTIPlayerResponse:       videoDetails=1  streamingData=1
 *   YTIStreamingData:        hlsManifestURL=1
 *   YTIVideoDetails:         thumbnail=1
 *   YTIThumbnailDetails:     thumbnailsArray=1
 *
 * On a PASS the log line looks like:
 *   P9PROBE vc=1 contentPlayerResponse=1 playerResponse=0 playerData=1 videoDetails=1 streamingData=1 hlsManifestURL=1 thumbnail=1 thumbnailsArray=1 STATUS=PASS
 *
 * On FAIL (original broken binary or partial migration) it looks like:
 *   P9PROBE vc=1 contentPlayerResponse=0 playerResponse=1 ... STATUS=FAIL
 *
 * Grep command (device console / device log captured file):
 *   grep P9PROBE <logfile>
 *   idevicesyslog | grep P9PROBE
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

%ctor {
    /* ---- resolve classes (nil-safe: BOOL expressions short-circuit) ---- */
    Class vcClass            = NSClassFromString(@"YTPlayerViewController");
    Class playerRespClass    = NSClassFromString(@"YTPlayerResponse");
    Class iPlayerRespClass   = NSClassFromString(@"YTIPlayerResponse");
    Class streamingDataClass = NSClassFromString(@"YTIStreamingData");
    Class videoDetailsClass  = NSClassFromString(@"YTIVideoDetails");
    Class thumbDetailsClass  = NSClassFromString(@"YTIThumbnailDetails");

    /* ---- probe the fixed selector and the dead one ---- */
    BOOL vc                   = (vcClass != nil);
    BOOL contentPlayerResp    = vc && [vcClass instancesRespondToSelector:@selector(contentPlayerResponse)];
    BOOL playerResp           = vc && [vcClass instancesRespondToSelector:@selector(playerResponse)]; // must be 0

    /* ---- probe downstream chain (mirrors Downloading.x) ---- */
    BOOL playerData           = (playerRespClass   != nil) && [playerRespClass   instancesRespondToSelector:@selector(playerData)];
    BOOL videoDetails         = (iPlayerRespClass  != nil) && [iPlayerRespClass  instancesRespondToSelector:@selector(videoDetails)];
    BOOL streamingData        = (iPlayerRespClass  != nil) && [iPlayerRespClass  instancesRespondToSelector:@selector(streamingData)];
    BOOL hlsManifestURL       = (streamingDataClass!= nil) && [streamingDataClass instancesRespondToSelector:@selector(hlsManifestURL)];
    BOOL thumbnail            = (videoDetailsClass != nil) && [videoDetailsClass  instancesRespondToSelector:@selector(thumbnail)];
    BOOL thumbnailsArray      = (thumbDetailsClass != nil) && [thumbDetailsClass  instancesRespondToSelector:@selector(thumbnailsArray)];

    /* ---- compute pass/fail ---- */
    BOOL pass = vc
             && contentPlayerResp   == YES
             && playerResp          == NO   /* dead selector must be absent */
             && playerData
             && videoDetails
             && streamingData
             && hlsManifestURL
             && thumbnail
             && thumbnailsArray;

    NSLog(@"P9PROBE vc=%d contentPlayerResponse=%d playerResponse=%d"
          @" playerData=%d videoDetails=%d streamingData=%d"
          @" hlsManifestURL=%d thumbnail=%d thumbnailsArray=%d"
          @" STATUS=%@",
          (int)vc,
          (int)contentPlayerResp,
          (int)playerResp,
          (int)playerData,
          (int)videoDetails,
          (int)streamingData,
          (int)hlsManifestURL,
          (int)thumbnail,
          (int)thumbnailsArray,
          pass ? @"PASS" : @"FAIL");
}
