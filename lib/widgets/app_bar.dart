import 'package:Apviser/CommonHelper.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';


import '../AppConstants.dart';
import '../colours.dart';
// import '../constants/app_colors.dart'; // Import your color constants
// import '../constants/app_constants.dart'; // Import app constants

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final double? fontSize;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.fontSize=18.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final effectiveFontSize = isSmallScreen ? 14.0 : fontSize;

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child:
      SafeArea( // Prevent touching the status bar
        child:

        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: AppConstants.APP_MAX_WIDTH),
            child: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.primary,
              elevation: 0,
              title:
              AutoSizeText(
                CommonHelper.htmlToTruncatedPlainText(title, 150),
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                minFontSize: 12, // will shrink if needed
                overflow: TextOverflow.ellipsis,
              ),
              // Text(
              //   CommonHelper.htmlToTruncatedPlainText(title, 150),
              //   style: const TextStyle(
              //     fontSize: 18.0,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.white,
              //     overflow: TextOverflow.ellipsis,
              //   ),
              //   textAlign: TextAlign.center,
              //   maxLines: 1,
              // ),

              centerTitle: true, // Properly center the title
              leading: showBackButton
                  ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
                  : const SizedBox(width: kToolbarHeight),
              actions: actions?.isNotEmpty == true
                  ? actions
                  : [const SizedBox(width: kToolbarHeight)], // Mirror spacing
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
