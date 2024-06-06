import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:spotube/provider/authentication_provider.dart';
import 'package:spotube/utils/platform.dart';

class WebViewLogin extends HookConsumerWidget {
  static const name = "login";
  const WebViewLogin({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final authenticationNotifier = ref.watch(authenticationProvider.notifier);

    if (kIsDesktop) {
      const Scaffold(
        body: Center(
          child: Text('This feature is not available on desktop'),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialSettings: InAppWebViewSettings(
            userAgent:
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 afari/537.36",
          ),
          initialUrlRequest: URLRequest(
            url: WebUri("https://accounts.spotify.com/"),
          ),
          onPermissionRequest: (controller, permissionRequest) async {
            return PermissionResponse(
              resources: permissionRequest.resources,
              action: PermissionResponseAction.GRANT,
            );
          },
          onLoadStop: (controller, action) async {
            if (action == null) return;
            String url = action.toString();
            if (url.endsWith("/")) {
              url = url.substring(0, url.length - 1);
            }

            final exp = RegExp(r"https:\/\/accounts.spotify.com\/.+\/status");

            if (exp.hasMatch(url)) {
              final cookies =
                  await CookieManager.instance().getCookies(url: action);
              final cookieHeader =
                  "sp_dc=${cookies.firstWhere((element) => element.name == "sp_dc").value}";

              authenticationNotifier.setCredentials(
                await AuthenticationCredentials.fromCookie(cookieHeader),
              );
              if (context.mounted) {
                // ignore: use_build_context_synchronously
                GoRouter.of(context).go("/");
              }
            }
          },
        ),
      ),
    );
  }
}
