/// Returns true only for signal lines from xcodebuild output.
/// Drops per-file compile/link/copy lines and pod deprecation noise,
/// keeping errors, phase headers, signing/export actions, and result banners.
bool xcodeLogFilter(String line) {
  if (line.trim().isEmpty) return false;

  // Always keep errors and final result banners
  if (line.contains(': error:') || line.startsWith('error:')) return true;
  if (line.contains('** BUILD') ||
      line.contains('** ARCHIVE') ||
      line.contains('** EXPORT')) return true;

  // Phase / target headers
  if (line.startsWith('=== ')) return true;

  // Signing, archiving, exporting, script execution
  if (line.startsWith('PhaseScriptExecution') ||
      line.startsWith('Signing') ||
      line.startsWith('Archiving') ||
      line.startsWith('Exporting') ||
      line.startsWith('CreateUniversalBinary') ||
      line.startsWith('GenerateDSYMFile') ||
      line.startsWith('RegisterWithLaunchServices')) return true;

  // Drop per-file compile / link / copy / metadata noise
  if (line.startsWith('CompileSwift') ||
      line.startsWith('CompileC') ||
      line.startsWith('CompileAssetCatalog') ||
      line.startsWith('Ld ') ||
      line.startsWith('CopySwiftLibs') ||
      line.startsWith('CpResource') ||
      line.startsWith('CopyPlistFile') ||
      line.startsWith('ProcessInfoPlistFile') ||
      line.startsWith('Libtool') ||
      line.startsWith('SwiftDriver') ||
      line.startsWith('SwiftMergeGeneratedHeaders') ||
      line.startsWith('WriteAuxiliaryFile') ||
      line.startsWith('MkDir') ||
      line.startsWith('SymLink') ||
      line.startsWith('Touch ') ||
      line.startsWith('Build settings') ||
      line.startsWith('User defaults')) return false;

  // Drop warning / note lines (mostly pod deprecation spam)
  if (line.startsWith('warning:') ||
      line.startsWith('note:') ||
      line.contains(': warning:') ||
      line.contains(': note:')) return false;

  return true;
}
