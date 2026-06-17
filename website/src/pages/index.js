import clsx from 'clsx';
import Link from '@docusaurus/Link';
import Layout from '@theme/Layout';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';

const copy = {
  en: {
    layoutTitle: 'Documentation',
    description:
      'Human-friendly date and time utilities for Mojo, inspired by Arrow and focused on parsing, formatting, time zone conversion, spans, ranges, and relative time.',
    primaryAction: 'Get started',
    secondaryAction: 'API reference',
    codeLabel: 'Morrow Mojo example',
    codeMeta: 'UTC + fixed offsets',
    features: [
      {
        title: 'UTC by default',
        text: 'Construct dates, timestamps, and fixed-offset time zones with predictable UTC behavior.',
      },
      {
        title: 'Arrow-style formatting',
        text: 'Use tokens such as YYYY, MMMM, Do, ZZ, X, and x for compact parsing and output.',
      },
      {
        title: 'Spans and relative time',
        text: 'Shift dates, iterate ranges, calculate spans, and humanize or dehumanize English distances.',
      },
    ],
  },
  'zh-Hans': {
    layoutTitle: '文档',
    description:
      '面向 Mojo 的友好日期时间工具库，受 Arrow 启发，专注于解析、格式化、时区转换、时间段、范围和相对时间。',
    primaryAction: '快速开始',
    secondaryAction: 'API 参考',
    codeLabel: 'Morrow Mojo 示例',
    codeMeta: 'UTC + 固定偏移',
    features: [
      {
        title: '默认 UTC',
        text: '以可预测的 UTC 行为构造日期、时间戳和固定偏移时区。',
      },
      {
        title: 'Arrow 风格格式化',
        text: '使用 YYYY、MMMM、Do、ZZ、X 和 x 等 token 进行紧凑解析和输出。',
      },
      {
        title: '时间段和相对时间',
        text: '偏移日期、遍历范围、计算时间段，并人性化描述或反向解析英文距离。',
      },
    ],
  },
};

export default function Home() {
  const {siteConfig, i18n} = useDocusaurusContext();
  const localeCopy = copy[i18n.currentLocale] ?? copy.en;

  return (
    <Layout title={localeCopy.layoutTitle} description={localeCopy.description}>
      <main className="morrow-home">
        <section className="morrow-hero">
          <div className="container morrow-hero__inner">
            <div>
              <h1>{siteConfig.title}</h1>
              <p>{localeCopy.description}</p>
              <div className="morrow-actions">
                <Link className="button button--primary" to="/docs/getting-started">
                  {localeCopy.primaryAction}
                </Link>
                <Link className="button button--secondary" to="/docs/api-reference">
                  {localeCopy.secondaryAction}
                </Link>
              </div>
            </div>
            <div className="morrow-code" aria-label={localeCopy.codeLabel}>
              <div className="morrow-code__bar">
                <span className="morrow-code__dots" aria-hidden="true">
                  <span />
                  <span />
                  <span />
                </span>
                <span>Mojo</span>
                <span>{localeCopy.codeMeta}</span>
              </div>
              <pre>
                <code>{`from morrow import Morrow

var utc = Morrow.get("2026-01-01 03:04:05Z")
print(utc)

var local = utc.to("+08:00")
print(local.format("YYYY-MM-DD HH:mm:ss ZZ"))`}</code>
              </pre>
            </div>
          </div>
        </section>
        <section className={clsx('container', 'morrow-grid')}>
          {localeCopy.features.map((feature) => (
            <article className="morrow-card" key={feature.title}>
              <h2>{feature.title}</h2>
              <p>{feature.text}</p>
            </article>
          ))}
        </section>
      </main>
    </Layout>
  );
}
