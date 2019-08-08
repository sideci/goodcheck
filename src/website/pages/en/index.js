/**
 * Copyright (c) 2017-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

const React = require('react');

class Splash extends React.Component {
  render() {
    return (
      <div className="feature-container">
        <FeatureDescription
          title={this.props.info.title}
          description={this.props.info.description}
          button={this.props.info.button}
        />
        <FeatureCodeBoxExtended info={this.props.info} />
      </div>
    );
  }
}

const Button = props => (
  <div className="plugin-wrapper button-wrapper">
    <a className="button" href={props.href} target={props.target}>
      {props.children}
    </a>
  </div>
);

class Section extends React.Component {
  render() {

    return (
      <div className="section-container">
        <div className="section-grid">
          <div className="section-card">
            <div>
              <h2>Configuration</h2>
              <p>Learn the patterns and syntax to make custom rules. </p>
              <Button href="./docs/configuration">Syntax details</Button>
            </div>
          </div>
          <div className="section-card">
            <div>
              <h2>Rules</h2>
              <p>
                Want to see some pre-defined rules? Check out some rules here.
              </p>
              <Button href="./docs/rules">See rules</Button>
            </div>
          </div>
          <div className="section-card">
            <div>
              <h2>Commands</h2>
              <p>
                Goodcheck is written to be used on the command line. Learn about
                it’s usage here.
              </p>
              <Button href="./docs/commands">CLI details</Button>
            </div>
          </div>
        </div>
      </div>
    );
  }
}

class Feature extends React.Component {
  render() {
    return (
      <div className="center-container">
        <div className="feature-container">
          <FeatureDescription
            title={this.props.info.title}
            description={this.props.info.description}
          />
          <FeatureCodeBoxExtended info={this.props.info} />
        </div>
      </div>
    );
  }
}

class FeatureDescription extends React.Component {
  render() {
    return (
      <div className="description-container">
        <h1>{this.props.title}</h1>
        <p>{this.props.description}</p>
        {this.props.button && (
          <Button href="./docs/getstarted">{this.props.button}</Button>
        )}
      </div>
    );
  }
}

class FeatureCodeBoxExtended extends React.Component {
  render() {
    const info = this.props.info;
    return (
      <div className="code-container">
        <header className="code-top">goodcheck.yml</header>
        <section className="code-content">
          <pre className="yaml">
            <span className="yaml-key">rules</span>
            <span className="yaml-syntax">: </span>
            <br />
            <span className="yaml-syntax">{`  - `}</span>
            <span className="yaml-key">id</span>
            <span className="yaml-syntax">: </span>
            <span className="yaml-value">{info.id}</span>
            <br />
            {info.not && (
              <div>
                <span className="yaml-key">{`    not`}</span>
                <span className="yaml-syntax">: </span>
                <br />
                <span className="yaml-key">{`      pattern`}</span>
                <span className="yaml-syntax">: </span>
                <span className="yaml-value">{info.pattern}</span>
                <br />
              </div>
            )}
            {!info.not && (
              <div>
                {info.pattern && (
                  <div>
                    <span className="yaml-key">{`    pattern`}</span>
                    <span className="yaml-syntax">: </span>
                    <span className="yaml-value">{info.pattern}</span>
                  </div>
                )}
              </div>
            )}
            <span className="yaml-key">{`    message`}</span>
            <span className="yaml-syntax">: </span>
            <span className="yaml-value">{`${info.message}`}</span>
            <br />
            {info.glob && (
              <div>
                <span className="yaml-key">{`    glob`}</span>
                <span className="yaml-syntax">: </span>
                <span className="yaml-value">{`${info.glob}`}</span>
              </div>
            )}
          </pre>
        </section>
        <header className="code-result">Result</header>
        <section className="code-terminal">
          <p className="yaml">
            {`${info.resultFront}`}
            {info.match && (
              <span className="terminal-highlight"> {info.match} </span>
            )}
            {info.resultEnd && `${info.resultEnd}`}
          </p>
        </section>
      </div>
    );
  }
}

class Index extends React.Component {
  render() {
    const { config: siteConfig } = this.props;

    const Showcase = () => {

      return (
        <div className="productShowcaseSection paddingBottom showcaseBackground">
          <br />
          <h2>Stop reviewing the same patterns.</h2>
          <Button href="./docs/getstarted">Start using {siteConfig.title}</Button>
        </div>
      );
    };

    const MainContainer = () => {
      return (
        <div className="index-container">
          <div className="splash-container">
            <Splash info={siteConfig.splash} />
          </div>
          <div className="three-features-container">
            <Section />
            <Feature info={siteConfig.featureOne} />
            <Feature info={siteConfig.featureTwo} />
            <Feature info={siteConfig.featureThree} />
          </div>
        </div>
      );
    }

    return (
      <div>
        <MainContainer />
        <Showcase />
      </div>
    );
  }
}

module.exports = Index;
