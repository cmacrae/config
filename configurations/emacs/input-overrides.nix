{ lib, ... }:
{
  evil-easymotion = _: prev: {
    packageRequires = {
      evil = "0";
    } // prev.packageRequires;
  };
}
