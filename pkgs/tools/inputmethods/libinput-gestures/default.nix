{ lib, stdenv, fetchFromGitHub, makeWrapper,
  libinput, wmctrl, python3,
  coreutils, xdotool ? null,
  extraUtilsPath ? lib.optional (xdotool != null) xdotool
}:
stdenv.mkDerivation rec {
  pname = "libinput-gestures";
  version = "2.77";

  src = fetchFromGitHub {
    owner = "bulletmark";
    repo = "libinput-gestures";
    rev = version;
    hash = "sha256-eMXNlSgQSuN+/5SXJQjsylC1ygHS87sIEmnVGFk3pzA=";
  };
  patches = [
    ./0001-hardcode-name.patch
    ./0002-paths.patch
  ];

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ python3 ];

  postPatch =
    ''
      substituteInPlace libinput-gestures-setup --replace /usr/ /

      substituteInPlace libinput-gestures \
        --replace      /etc     "$out/etc" \
        --subst-var-by libinput "${libinput}/bin/libinput" \
        --subst-var-by wmctrl   "${wmctrl}/bin/wmctrl"
    '';
  installPhase =
    ''
      runHook preInstall
      ${stdenv.shell} libinput-gestures-setup -d "$out" install
      runHook postInstall
    '';
  postFixup =
    ''
      rm "$out/bin/libinput-gestures-setup"
      substituteInPlace "$out/share/systemd/user/libinput-gestures.service" --replace "/usr" "$out"
      substituteInPlace "$out/share/applications/libinput-gestures.desktop" --replace "/usr" "$out"
      chmod +x "$out/share/applications/libinput-gestures.desktop"
      wrapProgram "$out/bin/libinput-gestures" --prefix PATH : "${lib.makeBinPath ([coreutils] ++ extraUtilsPath)}"
    '';

  meta = with lib; {
    homepage = "https://github.com/bulletmark/libinput-gestures";
    description = "Gesture mapper for libinput";
    mainProgram = "libinput-gestures";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = with maintainers; [ teozkr ];
  };
}
