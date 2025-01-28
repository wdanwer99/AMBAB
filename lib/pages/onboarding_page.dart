import 'package:agriplant/pages/home_page.dart';
import 'package:agriplant/pages/login_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: Center(
          child: isLandscape
              ? Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 250),
                            child: Image.asset(
                                'assets/logo.png'), // Add the logo image
                          ),
                          const SizedBox(height: 20),
                          Text('Welcome to AMBAB CO.LTD',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const Padding(
                            padding: EdgeInsets.only(top: 30, bottom: 30),
                            child: Text(
                              "Get your agriculture products from the comfort of your home. You're just a few clicks away from your favorite products.",
                              textAlign: TextAlign.center,
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                  CupertinoPageRoute(
                                      builder: (context) => const LoginPage()));
                            },
                            icon: const Icon(IconlyLight.login),
                            label: const Text("Continue to the app"),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: Image.asset('assets/onboarding.png'),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    const Spacer(),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Image.asset('assets/onboarding.png'),
                    ),
                    const SizedBox(height: 20), // Add space between the images
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 250),
                      child:
                          Image.asset('assets/logo.png'), // Add the logo image
                    ),
                    const Spacer(),
                    Text('Welcome to AMBAB CO.LTD',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Padding(
                      padding: EdgeInsets.only(
                          top: 42,
                          bottom: 50), // Adjust padding to raise the button
                      child: Text(
                        "Get your agriculture products from the comfort of your home. You're just a few clicks away from your favorite products.",
                        textAlign: TextAlign.center,
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                            CupertinoPageRoute(
                                builder: (context) => const LoginPage()));
                      },
                      icon: const Icon(IconlyLight.login),
                      label: const Text("Continue to the app"),
                    )
                  ],
                ),
        ),
      ),
    );
  }
}
