import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { addProject, initialize, readWorkspace, resolveBundle, seal, skillRoot, verifyBundle } from '../../skills/forge-workspace/scripts/workspace.mjs';

let temporary;
let oldCache;
const read = (file) => JSON.parse(fs.readFileSync(file, 'utf8'));
const create = (name = 'sample') => {
  const target = path.join(temporary, name);
  initialize({ target, name: 'example' });
  return target;
};

beforeEach(() => {
  temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'forge-generator-test-'));
  oldCache = process.env.FORGE_CACHE_DIR;
  process.env.FORGE_CACHE_DIR = path.join(temporary, 'cache');
});

afterEach(() => {
  if (oldCache === undefined) delete process.env.FORGE_CACHE_DIR;
  else process.env.FORGE_CACHE_DIR = oldCache;
  fs.rmSync(temporary, { recursive: true, force: true });
});

describe('工作区生成与扩展', () => {
  it('在含空格的路径生成四个可登记项目和完整隐藏配置', () => {
    const target = create('path with spaces');
    const metadata = readWorkspace(target);
    expect(metadata.projects.map((item) => item.name)).toEqual(['contracts', 'database', 'api', 'web']);
    expect(read(path.join(target, 'apps/web/package.json')).dependencies['@example/contracts']).toBe('workspace:*');
    for (const file of ['.env', '.env.example', '.gitignore', '.github/workflows/check.yaml', 'apps/api/.swcrc', 'docs/index.md']) expect(fs.existsSync(path.join(target, file))).toBe(true);
    expect(fs.readFileSync(path.join(target, 'docs/projects/index.md'), 'utf8')).toContain('[web](web.md)');
    expect(metadata.bundle.digest).toBe(verifyBundle().digest);
  });

  it('拒绝覆盖已有目录或把非法名称当作路径', () => {
    const target = create();
    fs.writeFileSync(path.join(target, 'user.txt'), '保留内容');
    expect(() => initialize({ target, name: 'new-name' })).toThrow('目标必须为空');
    expect(() => initialize({ target: path.join(temporary, 'bad'), name: '../bad' })).toThrow('名称须为');
    expect(fs.readFileSync(path.join(target, 'user.txt'), 'utf8')).toBe('保留内容');
  });

  it('连续新增前端、后端、共享包，保留人工导航和根配置', () => {
    const target = create();
    const rootPackage = fs.readFileSync(path.join(target, 'package.json'), 'utf8');
    fs.appendFileSync(path.join(target, 'docs/projects/index.md'), '\n人工补充的项目说明。\n');
    addProject({ workspace: target, type: 'shared-package', name: 'utilities' });
    addProject({ workspace: target, type: 'react-app', name: 'admin', dependsOn: ['utilities'] });
    addProject({ workspace: target, type: 'nest-app', name: 'worker' });
    const metadata = readWorkspace(target);
    expect(metadata.projects.find((item) => item.name === 'admin').port).toBe(5174);
    expect(metadata.projects.find((item) => item.name === 'worker').port).toBe(3001);
    expect(read(path.join(target, 'apps/admin/package.json')).dependencies['@example/utilities']).toBe('workspace:*');
    expect(fs.readFileSync(path.join(target, 'docs/projects/index.md'), 'utf8')).toContain('人工补充的项目说明');
    expect(fs.readFileSync(path.join(target, 'package.json'), 'utf8')).toBe(rootPackage);
    expect(fs.existsSync(path.join(target, '.forge/operation.lock'))).toBe(false);
  });

  it('同名冲突、未登记同名包与浏览器数据库依赖均在写入前拒绝', () => {
    const target = create();
    expect(() => addProject({ workspace: target, type: 'react-app', name: 'web' })).toThrow('已存在');
    expect(() => addProject({ workspace: target, type: 'react-app', name: 'admin', dependsOn: ['database'] })).toThrow('仅允许后端');
    fs.mkdirSync(path.join(target, 'packages/manual'));
    fs.writeFileSync(path.join(target, 'packages/manual/package.json'), JSON.stringify({ name: '@example/admin' }));
    expect(() => addProject({ workspace: target, type: 'react-app', name: 'admin' })).toThrow('未登记的同名包');
    expect(fs.existsSync(path.join(target, 'apps/admin'))).toBe(false);
    expect(readWorkspace(target).projects).toHaveLength(4);
  });

  it('根配置改动或导航损坏时不覆盖现有内容', () => {
    const target = create();
    fs.appendFileSync(path.join(target, 'pnpm-workspace.yaml'), '\n# 用户新约定\n');
    expect(() => addProject({ workspace: target, type: 'react-app', name: 'admin' })).toThrow('基础配置已变更');
    expect(fs.existsSync(path.join(target, 'apps/admin'))).toBe(false);
    const other = create('other');
    fs.writeFileSync(path.join(other, 'docs/projects/index.md'), '人工管理');
    expect(() => addProject({ workspace: other, type: 'react-app', name: 'admin' })).toThrow('导航标记');
    expect(fs.existsSync(path.join(other, 'apps/admin'))).toBe(false);
  });

  it('拒绝通过符号链接向工作区之外写入', () => {
    const target = create();
    const outside = path.join(temporary, 'outside');
    fs.mkdirSync(outside);
    fs.symlinkSync(outside, path.join(target, 'apps/admin'));
    expect(() => addProject({ workspace: target, type: 'react-app', name: 'admin' })).toThrow('符号链接');
    expect(fs.readdirSync(outside)).toEqual([]);
  });

  it('操作锁阻止并发写入，错误返回保留已存在的锁', () => {
    const target = create();
    fs.writeFileSync(path.join(target, '.forge/operation.lock'), '12345\n');
    expect(() => addProject({ workspace: target, type: 'react-app', name: 'admin' })).toThrow('操作锁');
    expect(fs.readFileSync(path.join(target, '.forge/operation.lock'), 'utf8')).toBe('12345\n');
  });
});

describe('分发完整性与版本恢复', () => {
  it('模板或脚本内容被修改后拒绝使用旧清单', () => {
    const copy = path.join(temporary, 'skill');
    fs.cpSync(skillRoot, copy, { recursive: true });
    fs.appendFileSync(path.join(copy, 'scripts/workspace.sh'), '\n# 未重新封装的改动\n');
    expect(() => verifyBundle(copy)).toThrow('内容被修改');
  });

  it('技能升级后仍从初始化时的缓存获取旧版本', () => {
    const target = create();
    const expected = readWorkspace(target).bundle;
    const newer = path.join(temporary, 'newer');
    fs.cpSync(skillRoot, newer, { recursive: true });
    seal(newer, { version: '0.2.0' });
    const selected = resolveBundle(expected, newer);
    expect(selected).not.toBe(newer);
    expect(verifyBundle(selected).digest).toBe(expected.digest);
    addProject({ workspace: target, type: 'shared-package', name: 'old-compatible' }, selected);
    expect(readWorkspace(target).projects.at(-1).name).toBe('old-compatible');
  });

  it('未发布资源缓存缺失时明确失败，不回退最新版', () => {
    const target = create();
    const expected = readWorkspace(target).bundle;
    fs.rmSync(process.env.FORGE_CACHE_DIR, { recursive: true });
    const newer = path.join(temporary, 'newer');
    fs.cpSync(skillRoot, newer, { recursive: true });
    seal(newer, { version: '0.2.0' });
    expect(() => resolveBundle(expected, newer)).toThrow('缺少未发布模板');
  });

  it('无缓存时从准确的 Git 标签取回整套资源，标签内容被改写则拒绝', () => {
    const remote = path.join(temporary, 'remote');
    const fixture = path.join(remote, 'skills/forge-workspace');
    fs.mkdirSync(path.dirname(fixture), { recursive: true });
    fs.cpSync(skillRoot, fixture, { recursive: true });
    const bundle = seal(fixture, { version: '0.1.0', source: { repository: remote, ref: 'forge-workspace-v0.1.0', published: true } });
    const git = (...args) => {
      const result = spawnSync('git', ['-C', remote, ...args], { encoding: 'utf8' });
      if (result.status !== 0) throw new Error(result.stderr);
    };
    git('init');
    git('add', '.');
    git('-c', 'user.name=验收夹具', '-c', 'user.email=fixture@example.invalid', 'commit', '-m', '发布测试版本');
    git('tag', 'forge-workspace-v0.1.0');
    const current = path.join(temporary, 'current');
    fs.cpSync(fixture, current, { recursive: true });
    seal(current, { version: '0.2.0', source: { repository: remote, ref: 'forge-workspace-v0.2.0', published: false } });
    const expected = { version: bundle.version, digest: bundle.digest, source: bundle.source };
    const selected = resolveBundle(expected, current);
    expect(verifyBundle(selected).digest).toBe(bundle.digest);
    fs.rmSync(process.env.FORGE_CACHE_DIR, { recursive: true });
    fs.appendFileSync(path.join(fixture, 'SKILL.md'), '\n被改写的版本。\n');
    seal(fixture, { version: '0.1.0', source: bundle.source });
    git('add', '.');
    git('-c', 'user.name=验收夹具', '-c', 'user.email=fixture@example.invalid', 'commit', '-m', '改写夹具');
    git('tag', '-f', 'forge-workspace-v0.1.0');
    expect(() => resolveBundle(expected, current)).toThrow('版本或来源不匹配');
  });
});
