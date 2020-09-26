using Dash
using DashHtmlComponents
using DashCoreComponents

app =  dash()


app.layout = html_div() do
    html_h1("Interactive Visualizations"),
    html_blockquote(dcc_markdown("This is the 4th chapter of the [Dash Tutorial](/).
    The [previous chapter](/basic-callbacks) covered basic callback usage and the [next chapter](/state)
    describes how to share data between callbacks. Just getting started? Make sure to [install the necessary
    dependencies](/installation)")),
    dcc_markdown("
    The `DashCoreComponents` package includes a component called `Graph`.exec

    `Graph` renders interactive visualizations using the open source [plotly.js](https://github.com/plotly/plotly.js) JavaScript
    graphing library. Plotly.js supports over 35 chart types and renders charts in both vector-quality SVG and high-performance
    WebGL.

    The `figure` argument in the `dcc_graph` component is the same `figure` argument that is used by
    `plotlyjs.jl`, an open source Julia graphing library. Check out
    the [plotlyjs.jl documentation](http://juliaplots.org/PlotlyJS.jl/stable/) and gallery to learn more.

    Dash components are described declaratively by a set of attributes. All of these attributes can be updated by callback
    functions, but only a subset of these attributes are updated through user interaction, such as when you click on an
    option in a `Dropdown` component and the `value` property of that component changes.

    The `Graph` component has four attributes that can change through user interaction: `hoverData`, `clickData`, `selectedData`,
    and `relayoutData`. THese properties update when you hover over points, click on points, or select regions in a graph.

    Here's a simple example that prints these attributes to the screen.
    "),
    dcc_markdown("""
    ```
    using Dash
    using DashHtmlComponents
    using DashCoreComponents

    app = dash()

    app.layout = html_div() do
        dcc_input(id="input", value="initial value", type = "text"),
        html_div(id="output")
    end

    callback!(app, Output("output", "children"), Input("input", "value")) do input_value
        "You've entered \$(input_value)"
    end

    run_server(app, "0.0.0.0", 8000)
    ```
    """),

    dcc_markdown("""
    ### Update Graphs on Hover

    Let's update our world indicators example from the previous chapter by updating time series
    when we hover over points in our scatter plot.

    """),
    dcc_markdown("""

    ```
    using CSV
    using DataFrames
    using Dash
    using DashHtmlComponents
    using DashCoreComponents
    using PlotlyJS
    using PlotlyJS


    url = "https://plotly.github.io/datasets/country_indicators.csv"
    download(url, "country-indicators.csv")
    df = DataFrame(CSV.File("country-indicators.csv"))

    dropmissing!(df)

    rename!(df, Dict(:"Indicator Name" => "Indicator"))
    rename!(df, Dict(:"Country Name" => "Country"))

    available_indicators = unique(df[:, "Indicator"])
    years = unique(df[:, "Year"])

    app = dash()

    app.layout = html_div() do
        html_div(
            children = [
                html_div(
                    children = [
                        dcc_dropdown(
                            id = "crossfilter-xaxis-column",
                            options = [
                                (label = i, value = i)
                                for i in available_indicators
                            ],
                            value = "Fertility rate, total (births per woman)",
                        ),
                        dcc_radioitems(
                            id = "crossfilter-xaxis-type",
                            options = [
                                (label = i, value = i) for i in ["linear", "log"]
                            ],
                            value = "linear",
                        ),
                    ],
                    style = (width = "49%", display = "inline-block"),
                ),
                html_div(
                    children = [
                        dcc_dropdown(
                            id = "crossfilter-yaxis-column",
                            options = [
                                (label = i, value = i)
                                for i in available_indicators
                            ],
                            value = "Life expectancy at birth, total (years)",
                        ),
                        dcc_radioitems(
                            id = "crossfilter-yaxis-type",
                            options = [
                                (label = i, value = i) for i in ["linear", "log"]
                            ],
                            value = "linear",
                        ),
                    ],
                    style = (
                        width = "49%",
                        float = "right",
                        display = "inline-block",
                    ),
                ),
            ],
            style = (
                borderBottom = "thin lightgrey solid",
                backgroundColor = "rgb(250, 250, 250)",
                padding = "10px 5px",
            ),
        ),
        html_div(
            children = [dcc_graph(id = "crossfilter-indicator-scatter"),
                        dcc_slider(
                            id = "crossfilter-year-slider",
                            min = 0,
                            max = length(years) - 1,
                            value = 0,
                            marks = years,
                        )],
            style = (width = "49%", display = "inline-block", paddingBottom = "400px"),
        ),
        html_div(
            children = [
                dcc_graph(id = "x-time-series"),
                dcc_graph(id = "y-time-series"),
            ],
            style = (width = "49%", display = "inline-block"),
        )
    end

    callback!(
        app,
        Output("crossfilter-indicator-scatter", "figure"),
        Input("crossfilter-xaxis-column", "value"),
        Input("crossfilter-yaxis-column", "value"),
        Input("crossfilter-xaxis-type", "value"),
        Input("crossfilter-yaxis-type", "value"),
        Input("crossfilter-year-slider", "value"),
    ) do x_axis_value, y_axis_value, x_axis_type, y_axis_type, year_value

        dff = filter(row -> row.Year == years[year_value+1], df)

        x_axis_data = filter(row -> row.Indicator == x_axis_value, dff)[:, "Value"]
        y_axis_data = filter(row -> row.Indicator == y_axis_value, dff)[:, "Value"]
        country_names = filter(row -> row.Indicator == y_axis_value, dff)[:, "Country"]

        figure = (
            data = [
                (
                    x = x_axis_data,
                    y = y_axis_data,
                    type = "scatter",
                    mode = "markers",
                    text = country_names
                ),
            ],
            layout = (
                xaxis = ((title = x_axis_value), (type = x_axis_type)),
                yaxis = ((title = y_axis_value), (type = y_axis_type)),
            ),
        )

        return figure

    end

    callback!(
        app,
        Output("x-time-series", "figure"),
        Input("crossfilter-indicator-scatter", "hoverData"),
        Input("crossfilter-xaxis-column", "value"),
        Input("crossfilter-xaxis-type", "value"),
    ) do hoverData, x_axis_column_name, axis_type

        if hoverData == nothing
            return PreventUpdate()
        end

        country = hoverData[1][1][:text]

        dff = filter(row -> row.Country == country, df)
        dff = filter!(row -> row.Indicator == x_axis_column_name, dff)

        figure = (
            data = [
                (
                    x = dff[:, "Year"],
                    y = dff[:, "Value"],
                    type = "scatter",
                    mode = "markers+lines"
                )
            ],
            layout = (
                title = country,
                xaxis = ((title = "Year"), (type = axis_type)),
                yaxis = ((title = x_axis_column_name), (type = axis_type)),
            ),
        )

        return figure

    end

    callback!(
        app,
        Output("y-time-series", "figure"),
        Input("crossfilter-indicator-scatter", "hoverData"),
        Input("crossfilter-yaxis-column", "value"),
        Input("crossfilter-yaxis-type", "value"),
    ) do hoverData, y_axis_column_name, axis_type

        if hoverData == nothing
            return PreventUpdate()
        end

        country = hoverData[1][1][:text]

        dff = filter(row -> row.Country == country, df)
        dff = filter!(row -> row.Indicator == y_axis_column_name, dff)

        figure = (
            data = [
                (
                    x = dff[:, "Year"],
                    y = dff[:, "Value"],
                    type = "scatter",
                    mode = "markers+lines"
                )
            ],
            layout = (
                title = country,
                xaxis = ((title = "Year"), (type = axis_type)),
                yaxis = ((title = y_axis_column_name), (type = axis_type)),
            ),
        )

        return figure

    end

    run_server(app, "0.0.0.0", 8000)

    ```

    Try mousing over the points in the scatter plot on the left.
    Notice how the line graphs on the right update based off of the point that you are hovering over.

    """),

    dcc_markdown("""
    ### Generic Crossfilter Recipe

    Here's a slightly more generic example for crossfiltering across a six-column dataset.
    Each scatter plot's selection filters the underlying dataset.

    """),
    dcc_markdown("""

    ```
        ##CODE GOES HERE##
    ```

    """),
    dcc_markdown("""

    Try clicking and dragging in any of the plots to filter different regions.
    On every selection, the three graph callbacks are fired with the latest selected regions of each plot.
    A dataframe is filtered based off of the selected points and the graphs are replotted
    with the selected points highlighted and the selected region drawn as a dashed rectangle.

    """),

    dcc_markdown("""
    ### Current Limitations

    There are a few limitations in graph interactions right now.

    * It is not currently possible to customize the style of the hover interactions
    or the select box. This issue is being worked on in https://github.com/plotly/plotly.js/issues/1847.

    There's a lot that you can do  with these interactive plotting features. If you need
    help exploring your use case, open up a thread in the [Dash Community Forum](https://community.plotly.com/c/dash/julia/20)

    The next chapter of the Dash User Guide explains how to share data between
    callbacks.

    [Dash Tutorial Part 5: Sharing Data Between Callbacks](/sharing-data-between-callbacks)
    """)
end

run_server(app, "0.0.0.0", 8000)