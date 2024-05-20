import "package:flutter/material.dart";

class ResponsiveLayout extends StatelessWidget {

  ResponsiveLayout(
      {required this.mobileScaffold, required this.tabletScaffold, required this.desktopScaffold, super.key,});
  Widget mobileScaffold;
  Widget tabletScaffold;
  Widget desktopScaffold;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints){
        if(constraints.maxWidth < 500){
          return mobileScaffold;
        }else if(constraints.maxWidth < 1100){
          return tabletScaffold;
        }else{
          return desktopScaffold;
        }
      },
    );
  }
}
