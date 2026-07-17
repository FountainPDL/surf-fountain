# Surf Fountain release ProGuard/R8 rules.
# Add project-specific rules here as features land (Room, Hilt, and Compose
# all ship consumer rules in their AARs, so most of the boilerplate you'd
# expect to need here is already handled automatically by R8).

# Keep WebView JavaScript interfaces once we add any @JavascriptInterface
# classes (Content Downloader, page Q&A, etc. in later phases):
# -keepclassmembers class com.surffountain.browser.** {
#     @android.webkit.JavascriptInterface <methods>;
# }
