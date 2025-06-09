import pandas as pd
import numpy as np
import plotly.express as px

# Load and prepare data
url = "https://raw.githubusercontent.com/itscharukadeshan/sl_news_archive_data/refs/heads/main/archive/news_article_counts.csv"
df = pd.read_csv(url)
df["Date"] = pd.to_datetime(df["Date"])

# Create a full daily date range
full_dates = pd.date_range(start=df["Date"].min(), end=df["Date"].max(), freq="D")

# --- Chart 1: Smoothed Area by Newspaper ---
smoothed_by_source = pd.DataFrame()

for paper in df["Newspaper"].unique():
    subset = df[df["Newspaper"] == paper].set_index("Date").reindex(full_dates)
    subset["Newspaper"] = paper
    subset["ArticleCount"] = subset["ArticleCount"].interpolate(method="quadratic", limit_direction="both")
    subset = subset.reset_index().rename(columns={"index": "Date"})
    smoothed_by_source = pd.concat([smoothed_by_source, subset], ignore_index=True)

fig1 = px.area(
    smoothed_by_source,
    x="Date",
    y="ArticleCount",
    color="Newspaper",
    title="📰 News Articles Archive by Newspaper",
    template="plotly_dark"
)

# --- Chart 2: Smoothed Total Article Count (All Sources Combined) ---
df_total = df.groupby("Date").sum(numeric_only=True).reindex(full_dates)
df_total["Date"] = df_total.index
df_total["ArticleCount"] = df_total["ArticleCount"].interpolate(method="quadratic", limit_direction="both")

fig2 = px.area(
    df_total,
    x="Date",
    y="ArticleCount",
    title="📊 Total News Articles (All Newspapers Combined)",
    template="plotly_dark"
)

# --- Common Layout Enhancements ---
for fig in [fig1, fig2]:
    fig.update_layout(
        xaxis_title="📅 Date",
        yaxis_title="🗞️ Number of Articles",
        hovermode="x unified",
        font=dict(family="Segoe UI", size=14, color="white"),
        plot_bgcolor="#1e1e1e",
        paper_bgcolor="#1e1e1e",
        margin=dict(l=50, r=50, t=80, b=50),
        xaxis=dict(
            rangeselector=dict(
                buttons=[
                    dict(count=7, label="1w", step="day", stepmode="backward"),
                    dict(count=1, label="1m", step="month", stepmode="backward"),
                    dict(count=3, label="3m", step="month", stepmode="backward"),
                    dict(step="all", label="All")
                ],
                bgcolor="#333",
                font=dict(color="white")
            ),
            rangeslider=dict(visible=True),
            type="date",
            showgrid=True,
            tickformatstops=[
                dict(dtickrange=[None, 1000 * 60 * 60 * 24 * 31], value="%d %b %Y"),
                dict(dtickrange=[1000 * 60 * 60 * 24 * 31, 1000 * 60 * 60 * 24 * 120], value="%b %Y"),
                dict(dtickrange=[1000 * 60 * 60 * 24 * 120, None], value="%b %Y")
            ]
        )
    )

# --- Save both charts ---
fig1.write_html("docs/news_chart_by_newspaper.html")
fig2.write_html("docs/news_chart_total_only.html")

print("Charts saved to 'news_chart_by_newspaper.html' and 'news_chart_total_only.html'")