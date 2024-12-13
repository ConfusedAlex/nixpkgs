{
  stdenv,
  nodejs,
  fetchFromGitHub,
  fetchNpmDeps,
  buildGoModule,
  lib,
  npmHooks,
  wails,
  webkitgtk_4_0,
  pkg-config,
  wrapGAppsHook3,
  autoPatchelfHook,
}:
let
  pname = "ask-mai";
  version = "0.2.1";
  src = fetchFromGitHub {
    owner = "rainu";
    repo = "ask-mai";
    tag = "v${version}";
    hash = "sha256-ybIpnatPFCjo1xyAn4A+Ea7399m62YV3MYK4kaeEYPk=";
  };
  frontend = stdenv.mkDerivation (finalAttrs: {
    inherit pname version src;

    nativeBuildInputs = [
      nodejs
      npmHooks.npmConfigHook
    ];

    npmDeps = fetchNpmDeps {
      inherit (finalAttrs) pname version src;
      sourceRoot = "${finalAttrs.src.name}/frontend";
      hash = "sha256-hWbdF2AQgPvzWIruBuUya2VeHYDruOWtN2RyEnfvaXc=";
    };

    sourceRoot = "${finalAttrs.src.name}/frontend";
    npmPackFlags = [ "--ignore-scripts" ];

    buildPhase = ''
      runHook preBuild

      npm run build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      npm install --verbose

      mkdir $out/
      cp -r ./dist/* $out/

      runHook postInstall
    '';
  });
in
buildGoModule {
  inherit pname version src;

  vendorHash = "sha256-C07wJdOEWOWxEuOSS6DGOHI+KoiOkY8FhDV7QPZDi9Q=";

  nativeBuildInputs = [
    wails
    pkg-config
    wrapGAppsHook3
    autoPatchelfHook
  ];

  buildInputs = [
    webkitgtk_4_0
  ];

  postUnpack = ''
    cp -r ${frontend} $sourceRoot/frontend/dist
  '';

  buildPhase = ''
    runHook preBuild

    wails build -m -s -trimpath -skipbindings -devtools -tags webkit2_40 -o ask-mai

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r ./build/bin $out/bin

    runHook postInstall
  '';

  meta = {
    description = "A little UI-Application for asking Gen-AI";
    homepage = "https://github.com/rainu/ask-mai";
    mainProgram = "ask-mai";
    license = with lib.licenses; [ mit ];
    maintainers = with lib.maintainers; [ confusedalex ];
    platforms = lib.platforms.linux;
  };
}
