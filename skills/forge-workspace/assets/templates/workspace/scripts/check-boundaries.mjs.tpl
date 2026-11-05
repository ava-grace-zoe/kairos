import fs from 'node:fs';
import { builtinModules } from 'node:module';
import path from 'node:path';
import ts from 'typescript';

const metadata = JSON.parse(fs.readFileSync('.forge/workspace.json', 'utf8'));
const projects = metadata.projects.map((project) => ({
  ...project,
  directory: path.resolve(project.path),
  manifest: JSON.parse(fs.readFileSync(`${project.path}/package.json`, 'utf8')),
}));
const byName = new Map(projects.map((project) => [project.manifest.name, project]));
const errors = [];
const isServer = (project) => ['database', 'nest-app'].includes(project.type);
const walk = (folder) =>
  fs.existsSync(folder)
    ? fs
        .readdirSync(folder, { withFileTypes: true })
        .flatMap((entry) =>
          entry.name === 'generated'
            ? []
            : entry.isDirectory()
              ? walk(path.join(folder, entry.name))
              : [path.join(folder, entry.name)],
        )
    : [];

function inspectGraph(project, current = project, seen = new Set()) {
  if (seen.has(current.manifest.name)) return;
  seen.add(current.manifest.name);
  for (const dependency of Object.keys(current.manifest.dependencies ?? {})) {
    const target = byName.get(dependency);
    if (!target) continue;
    if (!isServer(project) && isServer(target))
      errors.push(`${project.path} 经 ${current.path} 依赖后端专用包 ${target.path}`);
    if (target.path.startsWith('apps/'))
      errors.push(`${current.path} 不能依赖另一个应用 ${target.path}`);
    inspectGraph(project, target, seen);
  }
}

for (const project of projects) {
  inspectGraph(project);
  for (const file of walk(`${project.path}/src`).filter(
    (name) => /\.tsx?$/.test(name) && !/\.test\.tsx?$/.test(name),
  )) {
    const source = ts.createSourceFile(
      file,
      fs.readFileSync(file, 'utf8'),
      ts.ScriptTarget.Latest,
      true,
    );
    function visit(node) {
      const specifier =
        ts.isImportDeclaration(node) || ts.isExportDeclaration(node)
          ? node.moduleSpecifier
          : ts.isCallExpression(node) &&
              (node.expression.kind === ts.SyntaxKind.ImportKeyword ||
                (ts.isIdentifier(node.expression) && node.expression.text === 'require'))
            ? node.arguments[0]
            : undefined;
      if (specifier && ts.isStringLiteral(specifier)) {
        const dependency = specifier.text;
        if (dependency.startsWith('.')) {
          const resolved = path.resolve(path.dirname(file), dependency);
          if (!resolved.startsWith(`${project.directory}${path.sep}`))
            errors.push(`${file} 通过相对路径越过项目边界：${dependency}`);
        } else {
          const packageName = dependency.startsWith('@')
            ? dependency.split('/').slice(0, 2).join('/')
            : dependency.split('/')[0];
          if (
            !isServer(project) &&
            (dependency.startsWith('node:') || builtinModules.includes(dependency))
          )
            errors.push(`${file} 在浏览器可用包中导入服务端模块：${dependency}`);
          if (
            byName.has(packageName) &&
            !(
              project.manifest.dependencies?.[packageName] ||
              project.manifest.peerDependencies?.[packageName]
            )
          )
            errors.push(`${file} 使用了未声明的共享包：${packageName}`);
        }
      }
      ts.forEachChild(node, visit);
    }
    visit(source);
  }
}

if (errors.length) {
  console.error(errors.join('\n'));
  process.exitCode = 1;
} else console.log(`依赖边界检查通过：${projects.length} 个项目。`);
