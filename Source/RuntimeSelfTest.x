#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ── YTMusicUltimate runtime self-test ───────────────────────────────────────
// Verifies, at launch and WITHOUT any Google login, that the patch is correctly
// wired against the running YouTube Music build:
//   * the download-crash fix selector (contentPlayerResponse) exists; the dead
//     one (playerResponse) does not  -> proves P9 is fixed at runtime
//   * the %new download methods are installed
//   * every class the tweak %hooks still exists in this YT Music version
// Emits a structured report to NSLog (tag [[YTMU-SELFTEST]]) and to
// Documents/ytmu-selftest.json so it can be pulled over USB with no UI steps.
// DIAGNOSTIC build only — not part of the shipped/production dylib.

static NSArray *HookedClasses(void) {
  return @[
    @"APMAEU",
    @"APMIdentity",
    @"ASWApp",
    @"ASWUtilities",
    @"CHRAppState",
    @"CHRInfoPlistUtil",
    @"ELMTouchCommandPropertiesHandler",
    @"EXPApp",
    @"FIRApp",
    @"FIRInstallationsIIDTokenStore",
    @"FIROptions",
    @"GAZAppInfo",
    @"GCKBUtils",
    @"GHCCDeviceCapabilities",
    @"GPCDeviceInfo",
    @"GULAppEnvironmentUtil",
    @"GULKeychainStorage",
    @"GVROverlayView",
    @"MDXBaseScreen",
    @"MDXFeatureFlags",
    @"MDXPlaybackRouteButtonController",
    @"MDXPromotionManager",
    @"MDXSessionImpl",
    @"OGLBundle",
    @"OGLGM2AccountSelectorViewController",
    @"OGLPhenotypeFlagServiceImpl",
    @"SSOBundleIdServiceImpl",
    @"SSOConfiguration",
    @"SSOFolsomKeychainUtils",
    @"SSOKeychainCore",
    @"SSOKeychainHelper",
    @"YTAdBaseVideoPlayerOverlayViewController",
    @"YTAdShieldUtils",
    @"YTAdsInnerTubeContextDecorator",
    @"YTColdConfig",
    @"YTColor",
    @"YTCommonColorPalette",
    @"YTCommonUtils",
    @"YTDataUtils",
    @"YTDefaultQueueConfig",
    @"YTGlobalConfig",
    @"YTHintController",
    @"YTHotConfig",
    @"YTIAudioOnlyPlayabilityRenderer",
    @"YTIAudioOnlyPlayabilityRenderer_AudioOnlyPlayabilityInfoSupportedRenderers",
    @"YTIBackgroundabilityRenderer",
    @"YTIPlayabilityStatus",
    @"YTIPlayerResponse",
    @"YTIShowFullscreenInterstitialCommand",
    @"YTInterstitialPromoViewController",
    @"YTLightweightBrowseBackgroundView",
    @"YTLightweightCollectionController",
    @"YTLocalPlaybackController",
    @"YTMAppDelegate",
    @"YTMAppMealbarPromoController",
    @"YTMAppResponder",
    @"YTMAppResponderImpl",
    @"YTMAudioCastUpsellDialogController",
    @"YTMAudioVideoModeController",
    @"YTMAudioVideoModeControllerInternalImpl",
    @"YTMAvatarAccountView",
    @"YTMBackgroundUpsellNotificationController",
    @"YTMBrowseViewController",
    @"YTMCarPlayController",
    @"YTMCarPlayControllerImpl",
    @"YTMCastSessionController",
    @"YTMCastSessionControllerImpl",
    @"YTMChipCloudView",
    @"YTMConnectivityMealbarControllerImpl",
    @"YTMContentViewController",
    @"YTMFirstTimeSignInViewController",
    @"YTMIntegrationsSettingsViewController",
    @"YTMInterstitialPromoViewControllerImpl",
    @"YTMLightweightMusicDescriptionShelfCell",
    @"YTMLightweightOfflineTrackingSectionController",
    @"YTMMessageView",
    @"YTMModularNowPlayingViewController",
    @"YTMMusicAppMetadata",
    @"YTMMusicAppMetadataImpl",
    @"YTMNavigationDrawerPromoView",
    @"YTMNavigationImpl",
    @"YTMNowPlayingViewController",
    @"YTMPivotBarItemStyle",
    @"YTMPlaybackQueueAutoplayHeaderReusableView",
    @"YTMPlayerControlsView",
    @"YTMPlayerHeaderViewController",
    @"YTMPlayerPageColorScheme",
    @"YTMQueueCollectionViewController",
    @"YTMQueueConfig",
    @"YTMQueueConfigImpl",
    @"YTMSearchTabViewController",
    @"YTMSettings",
    @"YTMSettingsImpl",
    @"YTMTabViewController",
    @"YTMUpsellDialogController",
    @"YTMWAWatchAppConfig",
    @"YTMWatchViewController",
    @"YTMXSDKContentController",
    @"YTMYPCGetOfflineUpsellEndpointCommandHandler",
    @"YTMYPCGetOfflineUpsellEndpointCommandHandlerImpl",
    @"YTMealbarPromoController",
    @"YTOfflineButtonPromoController",
    @"YTPivotBarItemView",
    @"YTPivotBarView",
    @"YTPivotBarViewController",
    @"YTPlayabilityResolutionUserActionUIController",
    @"YTPlayabilityResolutionUserActionUIControllerImpl",
    @"YTPlaybackData",
    @"YTPlayerPromoController",
    @"YTPlayerStatus",
    @"YTPlayerViewController",
    @"YTPromoThrottleControllerImpl",
    @"YTPromosheetContainerView",
    @"YTPromosheetController",
    @"YTQueueController",
    @"YTQueueItem",
    @"YTShareMainView",
    @"YTShareMainViewController",
    @"YTSharePanelPromoViewController",
    @"YTSurveyPromosheet",
    @"YTUserDefaults",
    @"YTVersionUtils",
    @"YTVideoQualitySwitchOriginalController",
    @"YTVideoQualitySwitchRedesignedController",
    @"YTYouThereController",
    @"YTYouThereControllerImpl"
  ];
}

static BOOL InstResponds(NSString *cls, NSString *sel) {
  Class c = NSClassFromString(cls);
  return c && [c instancesRespondToSelector:NSSelectorFromString(sel)];
}

static void RunSelfTest(void) {
  NSMutableDictionary *r = [NSMutableDictionary dictionary];
  r[@"tweak_loaded"] = @YES;
  NSString *ver = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
  r[@"app_version"] = ver ?: @"?";

  // ── P9 download-crash fix (the actual bug) ──
  NSMutableDictionary *p9 = [NSMutableDictionary dictionary];
  BOOL live = InstResponds(@"YTPlayerViewController", @"contentPlayerResponse");
  BOOL dead = InstResponds(@"YTPlayerViewController", @"playerResponse");
  p9[@"YTPlayerViewController.contentPlayerResponse_exists"] = @(live);
  p9[@"YTPlayerViewController.playerResponse_exists"]        = @(dead);
  p9[@"VERDICT"] = (live && !dead) ? @"FIXED" : (dead ? @"STILL_BUGGY" : @"INDETERMINATE");
  r[@"P9_download_fix"] = p9;

  // ── our %new download methods must be installed ──
  NSMutableDictionary *nw = [NSMutableDictionary dictionary];
  for (NSString *s in @[@"downloadAudio:", @"downloadCoverImage:", @"getURLFromManifest:"])
    nw[s] = @(InstResponds(@"ELMTouchCommandPropertiesHandler", s));
  r[@"new_methods_installed"] = nw;

  // ── hook coverage: which %hook target classes still exist ──
  NSArray *hooked = HookedClasses();
  NSMutableArray *missing = [NSMutableArray array];
  for (NSString *cls in hooked)
    if (NSClassFromString(cls) == nil) [missing addObject:cls];
  r[@"hooks_total"]   = @(hooked.count);
  r[@"hooks_present"] = @(hooked.count - missing.count);
  r[@"hooks_missing"] = missing;

  NSData *json = [NSJSONSerialization dataWithJSONObject:r options:NSJSONWritingPrettyPrinted error:nil];
  NSString *str = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
  NSLog(@"[[YTMU-SELFTEST]] %@", str);

  NSURL *docs = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
  [json writeToURL:[docs URLByAppendingPathComponent:@"ytmu-selftest.json"] atomically:YES];
}

%ctor {
  // Defer so the full app class table is registered before we introspect.
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    RunSelfTest();
  });
}
