import clsx from 'clsx';
import Link from '@docusaurus/Link';
import Layout from '@theme/Layout';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';

const features = [
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
];

export default function Home() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout title="Documentation" description={siteConfig.tagline}>
      <main className="morrow-home">
        <section className="morrow-hero">
          <div className="container morrow-hero__inner">
            <div>
              <h1>{siteConfig.title}</h1>
              <p>
                Human-friendly date and time utilities for Mojo, inspired by
                Arrow and focused on parsing, formatting, time zone conversion,
                spans, ranges, and relative time.
              </p>
              <div className="morrow-actions">
                <Link className="button button--primary" to="/docs/getting-started">
                  Get started
                </Link>
                <Link className="button button--secondary" to="/docs/api-reference">
                  API reference
                </Link>
              </div>
            </div>
            <div className="morrow-code" aria-label="Morrow Mojo example">
              <div className="morrow-code__bar">
                <span className="morrow-code__dots" aria-hidden="true">
                  <span />
                  <span />
                  <span />
                </span>
                <span>Mojo</span>
                <span>UTC + fixed offsets</span>
              </div>
              <pre>
                <code>{`from morrow import Morrow, TimeZone

var utc = Morrow.utcnow()
print(str(utc))

var local = utc.to("+08:00")
print(local.format("YYYY-MM-DD HH:mm:ss ZZ"))`}</code>
              </pre>
            </div>
          </div>
        </section>
        <section className={clsx('container', 'morrow-grid')}>
          {features.map((feature) => (
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
