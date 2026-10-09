import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const [repository, tag, valuesPathArg] = process.argv.slice(2);

if (
  !repository ||
  !/^ghcr\.io\/[a-z0-9._/-]+$/.test(repository) ||
  !tag ||
  !/^[A-Za-z0-9_.-]+$/.test(tag)
) {
  throw new Error(
    "Usage: node update-gitops-image.mjs <ghcr-repository> <image-tag> [values.yaml]",
  );
}

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const valuesPath =
  valuesPathArg ??
  resolve(scriptDirectory, "../../weak 6/parallax-app/values.yaml");
const source = readFileSync(valuesPath, "utf8");
const lines = source.split(/\r?\n/);

for (const service of ["frontend", "backend"]) {
  const sectionStart = lines.findIndex((line) => line === `${service}:`);
  if (sectionStart < 0) {
    throw new Error(`Could not find the ${service} section in ${valuesPath}.`);
  }

  let sectionEnd = lines.length;
  for (let index = sectionStart + 1; index < lines.length; index += 1) {
    if (/^[^\s#][^:]*:\s*$/.test(lines[index])) {
      sectionEnd = index;
      break;
    }
  }

  const imageStart = lines.findIndex(
    (line, index) => index > sectionStart && index < sectionEnd && line === "  image:",
  );
  if (imageStart < 0) {
    throw new Error(`Could not find ${service}.image in ${valuesPath}.`);
  }

  const repositoryIndex = lines.findIndex(
    (line, index) =>
      index > imageStart && index < sectionEnd && /^    repository:\s*/.test(line),
  );
  const tagIndex = lines.findIndex(
    (line, index) =>
      index > imageStart && index < sectionEnd && /^    tag:\s*/.test(line),
  );
  if (repositoryIndex < 0 || tagIndex < 0) {
    throw new Error(`Could not find ${service}.image repository and tag in ${valuesPath}.`);
  }

  lines[repositoryIndex] = `    repository: ${repository}`;
  lines[tagIndex] = `    tag: "${tag}"`;
}

const newline = source.includes("\r\n") ? "\r\n" : "\n";
writeFileSync(valuesPath, lines.join(newline), "utf8");
console.log(`Updated frontend and backend image to ${repository}:${tag}.`);
