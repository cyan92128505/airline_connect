const fs = require("fs");
const path = require("path");

const newVersion = process.argv[2];
if (!newVersion) {
  console.error("Version parameter required");
  process.exit(1);
}

console.log(`Updating Flutter version to ${newVersion}`);

try {
  const pubspecPath = path.join(__dirname, "..", "pubspec.yaml");

  if (!fs.existsSync(pubspecPath)) {
    throw new Error("pubspec.yaml not found");
  }

  let content = fs.readFileSync(pubspecPath, "utf8");

  const versionMatch = content.match(/version:\s*(.+)/);
  if (!versionMatch) {
    throw new Error("Version field not found in pubspec.yaml");
  }

  const currentVersion = versionMatch[1].trim();
  let currentBuildNumber = 1;

  if (currentVersion.includes("+")) {
    const buildNumberStr = currentVersion.split("+")[1];
    currentBuildNumber = parseInt(buildNumberStr) || 1;
  }

  const newBuildNumber = currentBuildNumber + 1;
  const newFlutterVersion = `${newVersion}+${newBuildNumber}`;

  // 更新 pubspec.yaml
  const updatedContent = content.replace(
    /version:\s*.+/,
    `version: ${newFlutterVersion}`
  );

  fs.writeFileSync(pubspecPath, updatedContent, "utf8");

  console.log(`Updated pubspec.yaml: ${currentVersion} → ${newFlutterVersion}`);
} catch (error) {
  console.error(`Error updating version: ${error.message}`);
  process.exit(1);
}
