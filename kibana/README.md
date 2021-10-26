# Kibana artifacts

The `kibana` directory contains the following files for use with Kibana:

-   `export.ndsjon`\
    Saved objects exported from Kibana. These objects define sample dashboards for analyzing OMEGAMON attributes.

-   `omegamon-space.json`\
    The body of a Kibana create space API request.

## About the sample dashboards

The dashboards were developed on a screen with a resolution of 1920 &#x2715; 1080 pixels.

The "home" dashboard offers an entry point to the dashboards. The home dashboard is, essentially, an expanded version of the "menu bar" that appears at the top of most of the other dashboards.

Most of the dashboards are for analyzing attributes. However, the **Data inventory** dashboard is for analyzing the amount and types of attributes that have been ingested.

## Navigating between dashboards

To switch between dashboards, click a link in the row of links at the top of each dashboard.

Some dashboards offer drill-down links to other dashboards.

The developers of these dashboards look forward to future versions of Kibana offering better support for navigating between dashboards. For details, see Kibana issue [#99740](https://github.com/elastic/kibana/issues/99740), "Custom nested (cascading, flyout) menus of links in the Kibana sidebar".
