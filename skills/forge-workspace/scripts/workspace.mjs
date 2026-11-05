import { createHash } from 'node:crypto';
import * as fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

export const skillRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const repository = 'https://github.com/ava-grace-zoe/kairos';
const kinds = ['react-app', 'nest-app', 'shared-package'];
const managedConfigs = ['pnpm-workspace.yaml', 'tsconfig.base.json'];
const hash = (value) => createHash('sha256').update(value).digest('hex');
const readJson = (file) => JSON.parse(fs.readFileSync(file, 'utf8'));
const json = (value) => `${JSON.stringify(value, null, 2)}\n`;
const fail = (message) => { throw new Error(message); };

export function safePath(root, relative) {
  if (!relative || path.isAbsolute(relative) || relative.split(/[\\/]/).some((part) => part === '..')) fail(`非法相对路径：${relative}`);
  const result = path.resolve(root, relative);
  if (!result.startsWith(`${path.resolve(root)}${path.sep}`)) fail(`路径越界：${relative}`);
  let current = path.resolve(root);
  for (const part of relative.split('/')) {
    current = path.join(current, part);
    try { if (fs.lstatSync(current).isSymbolicLink()) fail(`拒绝通过符号链接修改文件：${current}`); } catch (error) { if (error.code !== 'ENOENT') throw error; }
  }
  return result;
}

function listFiles(root, relative = '') {
  return fs.readdirSync(path.join(root, relative), { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name, 'en')).flatMap((entry) => {
    const name = path.posix.join(relative, entry.name);
    if (entry.isSymbolicLink()) fail(`分发资源不能包含符号链接：${name}`);
    if (entry.isDirectory()) return listFiles(root, name);
    return entry.isFile() ? [name] : [];
  });
}

export function seal(root = skillRoot, options = {}) {
  const version = options.version ?? '0.1.0';
  const source = options.source ?? { repository, ref: `forge-workspace-v${version}`, published: false };
  const paths = ['SKILL.md', ...listFiles(root, 'scripts'), ...listFiles(root, 'assets')].sort();
  const files = paths.map((name) => ({ path: name, sha256: hash(fs.readFileSync(path.join(root, name))) }));
  const payload = { schemaVersion: 1, version, source, files };
  const bundle = { ...payload, digest: hash(JSON.stringify(payload)) };
  fs.writeFileSync(path.join(root, 'bundle.json'), json(bundle));
  return bundle;
}

export function verifyBundle(root = skillRoot, expected) {
  const bundle = readJson(path.join(root, 'bundle.json'));
  const { digest, ...payload } = bundle;
  if (bundle.schemaVersion !== 1 || !/^[a-f0-9]{64}$/.test(digest) || hash(JSON.stringify(payload)) !== digest) fail(`分发清单校验失败：${root}`);
  if (expected && (bundle.version !== expected.version || digest !== expected.digest || JSON.stringify(bundle.source) !== JSON.stringify(expected.source))) fail(`分发版本或来源不匹配：${root}`);
  for (const file of bundle.files) {
    if (!(file.path === 'SKILL.md' || /^(scripts|assets)\//.test(file.path))) fail(`非法分发文件：${file.path}`);
    const name = safePath(root, file.path);
    if (!fs.existsSync(name) || hash(fs.readFileSync(name)) !== file.sha256) fail(`资源缺失或内容被修改：${name}。维护者重新封装；使用者重新安装准确版本。`);
  }
  for (const required of ['SKILL.md', 'scripts/workspace.sh', 'scripts/workspace.mjs', 'assets/templates/workspace/package.json.tpl']) {
    if (!bundle.files.some((file) => file.path === required)) fail(`分发清单缺少必需资源：${required}`);
  }
  return bundle;
}

function cacheBase() {
  return path.resolve(process.env.FORGE_CACHE_DIR ?? path.join(os.homedir(), '.cache/kairos/forge-workspace'));
}

function cachePath(bundle) {
  if (!/^[0-9]+\.[0-9]+\.[0-9]+(?:-[a-zA-Z0-9.-]+)?$/.test(bundle.version) || !/^[a-f0-9]{64}$/.test(bundle.digest)) fail('工作区版本元数据无效。');
  return path.join(cacheBase(), `${bundle.version}-${bundle.digest}`);
}

export function cacheBundle(root, bundle) {
  const destination = cachePath(bundle);
  if (fs.existsSync(destination)) { verifyBundle(destination, bundle); return destination; }
  fs.mkdirSync(cacheBase(), { recursive: true });
  const stage = fs.mkdtempSync(path.join(cacheBase(), '.stage-'));
  try {
    for (const file of [...bundle.files, { path: 'bundle.json' }]) {
      const target = safePath(stage, file.path);
      fs.mkdirSync(path.dirname(target), { recursive: true });
      fs.copyFileSync(safePath(root, file.path), target);
    }
    verifyBundle(stage, bundle);
    try { fs.renameSync(stage, destination); }
    catch (error) {
      if (!fs.existsSync(destination)) throw error;
      verifyBundle(destination, bundle);
    }
    return destination;
  } finally { fs.rmSync(stage, { recursive: true, force: true }); }
}

export function resolveBundle(expected, currentRoot = skillRoot) {
  const current = verifyBundle(currentRoot);
  if (current.digest === expected.digest && current.version === expected.version) { verifyBundle(currentRoot, expected); return currentRoot; }
  const cached = cachePath(expected);
  if (fs.existsSync(cached)) { verifyBundle(cached, expected); return cached; }
  if (expected.source?.repository !== current.source.repository) fail('工作区模板来源与已安装技能不一致，拒绝执行其他来源的生成脚本。');
  if (!expected.source.published) fail(`缺少未发布模板 ${expected.version}（${expected.digest}）。从原机器恢复对应版本缓存，或安装原始技能副本；不会回退最新版。`);
  if (!/^forge-workspace-v[0-9]+\.[0-9]+\.[0-9]+(?:-[a-zA-Z0-9.-]+)?$/.test(expected.source.ref)) fail('工作区发布标签无效。');
  const stage = fs.mkdtempSync(path.join(os.tmpdir(), 'forge-fetch-'));
  try {
    const checkout = path.join(stage, 'repository');
    const result = spawnSync('git', ['clone', '--depth', '1', '--single-branch', '--branch', expected.source.ref, '--', expected.source.repository, checkout], { encoding: 'utf8', timeout: 120_000, env: { ...process.env, GIT_TERMINAL_PROMPT: '0' } });
    if (result.status !== 0) fail(`无法下载模板 ${expected.source.ref}。请检查仓库认证、网络和标签是否存在；不会回退最新版。\n${result.error?.message ?? result.stderr}`);
    const root = path.join(checkout, 'skills/forge-workspace');
    const bundle = verifyBundle(root, expected);
    const commit = spawnSync('git', ['-C', checkout, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).stdout.trim();
    console.error(`已校验模板来源提交：${commit}`);
    return cacheBundle(root, bundle);
  } finally { fs.rmSync(stage, { recursive: true, force: true }); }
}

function validName(value) {
  if (typeof value !== 'string' || value.length > 48 || !/^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/.test(value)) fail('名称须为 1–48 位小写字母、数字和单连字符，且以字母开头。');
  return value;
}

function renderDirectory(root, type, variables, destination) {
  const source = path.join(root, 'assets/templates', type);
  for (const relative of listFiles(source)) {
    if (!relative.endsWith('.tpl')) fail(`模板文件缺少 .tpl 后缀：${relative}`);
    const renderedName = relative.slice(0, -4).replaceAll('__dot__', '.');
    const target = safePath(destination, renderedName);
    let content = fs.readFileSync(path.join(source, relative), 'utf8');
    for (const [key, value] of Object.entries(variables)) content = content.replaceAll(`__${key}__`, String(value));
    if (/__(SCOPE|WORKSPACE|PROJECT_NAME|PORT|API_PORT)__/.test(content)) fail(`模板变量未替换：${relative}`);
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.writeFileSync(target, content, { flag: 'wx' });
  }
}

function projectDoc(project, scope) {
  const title = { 'react-app': '前端应用', 'nest-app': '后端服务', 'shared-package': '共享包', contracts: '接口契约', database: '数据库包' }[project.type];
  return `# ${project.name}\n\n## 概述\n\n${title}，路径为 \`${project.path}\`，包名为 \`@${scope}/${project.name}\`。\n\n## 文件结构\n\n源码在 \`src/\`，构建输出在 \`dist/\`；测试与被测模块就近组织。\n\n## 工作流程\n\n在工作区根目录执行：\n\n\`\`\`bash\npnpm --filter @${scope}/${project.name} build\npnpm --filter @${scope}/${project.name} typecheck\npnpm --filter @${scope}/${project.name} test\n\`\`\`\n\n先运行根目录 \`pnpm db:generate\` 和 \`pnpm build:packages\` 准备依赖。${project.port ? `服务默认端口为 ${project.port}；根目录 \`pnpm dev\` 会启动该应用。` : ''}\n\n## 当前进度\n\n- [x] 已生成基础代码及命令。\n- [ ] 在本地完成构建和测试；生成成功不能代替运行验收。\n\n## 已知问题\n\n${project.type === 'nest-app' ? '数据库相关功能需要先配置根目录 `.env` 并运行数据库迁移。' : '新增业务逻辑后同步补充行为测试与功能文档。'}\n`;
}

function updateNavigation(root, projects) {
  const file = safePath(root, 'docs/projects/index.md');
  const source = fs.readFileSync(file, 'utf8');
  const start = '<!-- forge:projects:start -->';
  const end = '<!-- forge:projects:end -->';
  if (source.split(start).length !== 2 || source.split(end).length !== 2 || source.indexOf(start) > source.indexOf(end)) fail('docs/projects/index.md 的项目导航标记缺失或重复，请恢复两个标记后重试。');
  const rows = projects.map((item) => `| [${item.name}](${item.name}.md) | ${item.type} | \`${item.path}\` |`).join('\n');
  return source.slice(0, source.indexOf(start)) + `${start}\n\n| 项目 | 类型 | 代码路径 |\n| --- | --- | --- |\n${rows}\n\n` + source.slice(source.indexOf(end));
}

function metadataBundle(bundle) { return { version: bundle.version, digest: bundle.digest, source: bundle.source }; }

export function initialize({ target, name }, root = skillRoot) {
  name = validName(name ?? path.basename(target));
  target = path.resolve(target);
  if (fs.existsSync(target) && (fs.lstatSync(target).isSymbolicLink() || !fs.statSync(target).isDirectory() || fs.readdirSync(target).length)) fail(`目标必须为空目录或不存在：${target}`);
  const bundle = verifyBundle(root);
  cacheBundle(root, bundle);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  const stage = fs.mkdtempSync(path.join(path.dirname(target), '.forge-init-'));
  try {
    const variables = { WORKSPACE: name, SCOPE: name, API_PORT: 3000 };
    renderDirectory(root, 'workspace', variables, stage);
    const projects = [
      { name: 'contracts', type: 'contracts', path: 'packages/contracts' },
      { name: 'database', type: 'database', path: 'packages/database' },
      { name: 'api', type: 'nest-app', path: 'apps/api', port: 3000 },
      { name: 'web', type: 'react-app', path: 'apps/web', port: 5173 },
    ];
    for (const project of projects) {
      if (kinds.includes(project.type)) renderDirectory(root, project.type, { ...variables, PROJECT_NAME: project.name, PORT: project.port }, path.join(stage, project.path));
      fs.writeFileSync(path.join(stage, `docs/projects/${project.name}.md`), projectDoc(project, name));
    }
    fs.writeFileSync(path.join(stage, 'docs/projects/index.md'), updateNavigation(stage, projects));
    fs.mkdirSync(path.join(stage, '.forge'), { recursive: true });
    const configs = Object.fromEntries(managedConfigs.map((file) => [file, hash(fs.readFileSync(path.join(stage, file)))]));
    fs.writeFileSync(path.join(stage, '.forge/workspace.json'), json({ schemaVersion: 1, name, bundle: metadataBundle(bundle), configs, projects }));
    fs.copyFileSync(path.join(stage, '.env.example'), path.join(stage, '.env'));
    if (fs.existsSync(target)) fs.rmdirSync(target);
    fs.renameSync(stage, target);
    return { target, projects };
  } finally { fs.rmSync(stage, { recursive: true, force: true }); }
}

export function readWorkspace(root) {
  const metadata = readJson(safePath(root, '.forge/workspace.json'));
  if (metadata.schemaVersion !== 1 || !Array.isArray(metadata.projects)) fail('不支持的工作区元数据；请使用其对应版本的技能。');
  validName(metadata.name);
  for (const project of metadata.projects) {
    validName(project.name);
    const file = safePath(root, `${project.path}/package.json`);
    if (readJson(file).name !== `@${metadata.name}/${project.name}`) fail(`项目登记与实际包名不一致：${file}`);
  }
  for (const file of managedConfigs) {
    if (hash(fs.readFileSync(safePath(root, file))) !== metadata.configs?.[file]) fail(`基础配置已变更：${file}。请先审查与原模板的兼容性并显式同步版本记录；新增项目不会覆盖配置或自动升级。`);
  }
  const pkg = readJson(safePath(root, 'package.json'));
  if (pkg.packageManager !== 'pnpm@10.28.0' || pkg.type !== 'module') fail('工作区包管理器或模块格式已改变，需先处理模板兼容性。');
  return metadata;
}

export function addProject({ workspace, type, name, dependsOn = [] }, root = skillRoot) {
  workspace = fs.realpathSync(path.resolve(workspace));
  name = validName(name);
  if (!kinds.includes(type)) fail(`未知项目类型：${type}；可选 ${kinds.join(', ')}。`);
  const lockPath = safePath(workspace, '.forge/operation.lock');
  let lock;
  try { lock = fs.openSync(lockPath, 'wx'); } catch { fail(`存在工作区操作锁：${lockPath}。检查其中进程是否仍在运行；确认已结束后删除该锁再重试。`); }
  fs.writeFileSync(lock, `${process.pid}\n`);
  let stage;
  const written = [];
  const backups = new Map();
  try {
    const metadata = readWorkspace(workspace);
    verifyBundle(root, metadata.bundle);
    const relative = `${type === 'shared-package' ? 'packages' : 'apps'}/${name}`;
    const destination = safePath(workspace, relative);
    const docFile = safePath(workspace, `docs/projects/${name}.md`);
    if (metadata.projects.some((item) => item.name === name) || fs.existsSync(destination) || fs.existsSync(docFile)) fail(`项目名称或路径已存在：${name}`);
    for (const folder of ['apps', 'packages']) {
      for (const item of fs.readdirSync(safePath(workspace, folder))) {
        const pkgFile = safePath(workspace, `${folder}/${item}/package.json`);
        if (fs.existsSync(pkgFile) && readJson(pkgFile).name === `@${metadata.name}/${name}`) fail(`发现未登记的同名包：${pkgFile}`);
      }
    }
    for (const dependency of dependsOn) {
      const project = metadata.projects.find((item) => item.name === dependency);
      if (!project || !project.path.startsWith('packages/')) fail(`依赖必须是已登记的共享包：${dependency}`);
      if (project.type === 'database' && type !== 'nest-app') fail('数据库包仅允许后端服务消费。');
    }
    let port = type === 'react-app' ? 5173 : type === 'nest-app' ? 3000 : undefined;
    while (port && metadata.projects.some((item) => item.port === port)) port += 1;
    const project = { name, type, path: relative, ...(port ? { port } : {}) };
    const projects = [...metadata.projects, project];
    const navigation = updateNavigation(workspace, projects);
    stage = fs.mkdtempSync(path.join(workspace, '.forge/.add-'));
    renderDirectory(root, type, { WORKSPACE: metadata.name, SCOPE: metadata.name, PROJECT_NAME: name, PORT: port ?? '', API_PORT: metadata.projects.find((item) => item.name === 'api')?.port ?? 3000 }, stage);
    if (dependsOn.length) {
      const file = path.join(stage, 'package.json');
      const pkg = readJson(file);
      pkg.dependencies ??= {};
      for (const dependency of dependsOn) pkg.dependencies[`@${metadata.name}/${dependency}`] = 'workspace:*';
      fs.writeFileSync(file, json(pkg));
    }
    for (const file of ['docs/projects/index.md', '.forge/workspace.json']) backups.set(safePath(workspace, file), fs.readFileSync(safePath(workspace, file)));
    fs.renameSync(stage, destination);
    stage = undefined;
    written.push(destination);
    fs.writeFileSync(docFile, projectDoc(project, metadata.name), { flag: 'wx' });
    written.push(docFile);
    fs.writeFileSync(safePath(workspace, 'docs/projects/index.md'), navigation);
    fs.writeFileSync(safePath(workspace, '.forge/workspace.json'), json({ ...metadata, projects }));
    return { target: workspace, project };
  } catch (error) {
    for (const file of written.reverse()) fs.rmSync(file, { recursive: true, force: true });
    for (const [file, content] of backups) fs.writeFileSync(file, content);
    throw error;
  } finally {
    if (stage) fs.rmSync(stage, { recursive: true, force: true });
    fs.closeSync(lock);
    fs.unlinkSync(lockPath);
  }
}

const help = `forge-workspace — 创建并扩展标准全栈工作区

前置条件：Node.js 22.23.2+ 的受支持偶数版本；生成后使用 pnpm 10.28.0。
用法：
  workspace.sh init --target <绝对或相对路径> [--name <名称>]
  workspace.sh add --workspace <工作区路径> --type <类型> --name <名称> [--depends-on <包名,包名>]
  workspace.sh verify

类型：react-app、nest-app、shared-package。
init 默认名称为目标目录名；默认生成 web、api、contracts、database。
add 自动分配工作区内未使用的端口，更新项目文档和版本登记，保留根配置。
名称：小写字母开头，最多 48 位，可含数字与单连字符。
生成器不安装依赖、不启动服务；成功输出绝对路径及后续命令。
FORGE_CACHE_DIR 可覆盖默认 ~/.cache/kairos/forge-workspace 缓存位置。
历史版本缓存缺失时只获取登记的发布标签，并校验内容；失败不会回退最新版。
退出码：0 成功；1 配置、冲突、环境或下载错误。具体原因写入标准错误。
恢复：生成成功但依赖安装失败时，在目标目录重试 pnpm install；不要重复生成。
`;

export function main(args) {
  const [command, ...rest] = args;
  if (!command || command === '--help' || command === '-h') { console.log(help); return; }
  const opts = {};
  const allowed = command === 'init' ? ['target', 'name'] : command === 'add' ? ['workspace', 'type', 'name', 'depends-on'] : [];
  for (let index = 0; index < rest.length; index += 2) {
    const key = rest[index]?.replace(/^--/, '');
    const value = rest[index + 1];
    if (!rest[index]?.startsWith('--') || !allowed.includes(key) || !value || value.startsWith('--') || opts[key]) fail(`无效或重复参数：${rest[index]}。运行 --help 查看用法。`);
    opts[key] = value;
  }
  if (command === 'verify') { const bundle = verifyBundle(); console.log(`资源校验通过：${bundle.version} ${bundle.digest}`); return; }
  let result;
  if (command === 'init') {
    if (!opts.target) fail('init 缺少 --target。');
    result = initialize(opts);
  } else if (command === 'add') {
    if (!opts.workspace || !opts.type || !opts.name) fail('add 需要 --workspace、--type 和 --name。');
    const workspace = fs.realpathSync(path.resolve(opts.workspace));
    const metadata = readWorkspace(workspace);
    const selected = resolveBundle(metadata.bundle);
    if (selected !== skillRoot) {
      const child = spawnSync(process.execPath, [path.join(selected, 'scripts/workspace.mjs'), ...args], { stdio: 'inherit', env: process.env });
      if (child.error) throw child.error;
      process.exitCode = child.status ?? 1;
      return;
    }
    result = addProject({ ...opts, dependsOn: opts['depends-on']?.split(',').map(validName) ?? [] });
  } else fail(`未知命令：${command}。运行 --help 查看用法。`);
  console.log(json(result));
  console.log(`在目标目录依次执行：\npnpm install\npnpm db:generate\npnpm check\n\n数据库联调：pnpm db:up && pnpm db:migrate\n浏览器准备：pnpm exec playwright install chromium\n完整验收：pnpm test:browser && pnpm test:system\n开发启动：pnpm dev`);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try { main(process.argv.slice(2)); }
  catch (error) { console.error(`[forge-workspace] ${error.message}`); process.exitCode = 1; }
}
