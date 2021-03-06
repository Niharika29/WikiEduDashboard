/* global vg */
import React from 'react';

const Wp10Graph = React.createClass({
  displayName: 'Wp10Graph',

  propTypes: {
    article: React.PropTypes.object
  },

  getInitialState() {
    return { showGraph: false };
  },

  showGraph() {
    this.setState({ showGraph: true });
    if (!this.state.rendered) {
      this.renderGraph();
    }
  },

  hideGraph() {
    this.setState({ showGraph: false });
  },

  graphId() {
    return `vega-graph-${this.props.article.id}`;
  },

  renderGraph() {
    const articleId = this.props.article.id;
    const vlSpec = {
      data: { url: `/articles/${articleId}.json` },
      layers: [
        {
          mark: 'area',
          encoding: {
            x: {
              field: 'date',
              type: 'temporal',
              axis: { labelAngle: 0 }
            },
            y: {
              field: 'wp10',
              type: 'quantitative',
              scale: { domain: [0, 100] },
              axis: { title: I18n.t('articles.wp10'), offset: 10 },
            }
          },
          config: {
            cell: { width: 500, height: 300 },
            mark: { fill: '#676EB4', interpolate: 'step-before' },
            timeFormat: '%b %d'
          }
        },
        {
          mark: 'circle',
          encoding: {
            x: {
              field: 'date',
              type: 'temporal'
            },
            y: {
              field: 'wp10',
              type: 'quantitative',
              scale: { domain: [0, 100] }
            }
          },
          config: {
            mark: { size: 100, fill: '#359178' }
          }
        }
      ]
    };
    const embedSpec = {
      mode: 'vega-lite', // Instruct Vega-Embed to use the Vega-Lite compiler
      spec: vlSpec,
      actions: false
    };
    vg.embed(`#${this.graphId()}`, embedSpec);
    this.setState({ rendered: true });
  },

  render() {
    // Only render the button if it is an en.wikipedia article, since only
    // those articles have wp10 scores.
    if (!this.props.article.url.match(/en.wikipedia/)) {
      return <div></div>;
    }

    let style;
    let button;
    if (this.state.showGraph) {
      style = '';
      button = <button onClick={this.hideGraph} className="button dark">Hide graph</button>;
    } else {
      style = ' hidden';
      button = <button onClick={this.showGraph} className="button dark">Show graph</button>;
    }
    const className = `vega-graph ${style}`;
    return (
      <div>
        {button}
        <div id={this.graphId()} className={className} />
      </div>
    );
  }
});

export default Wp10Graph;
