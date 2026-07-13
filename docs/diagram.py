from diagrams import Diagram, Cluster, Edge
from diagrams.aws.storage import S3
from diagrams.aws.analytics import Athena, GlueDataCatalog
from diagrams.onprem.analytics import Dbt
from diagrams.onprem.ci import GithubActions

graph_attrs = {"fontsize": "13", "bgcolor": "white", "pad": "0.5", "splines": "ortho"}
node_attrs = {"fontsize": "11"}

with Diagram(
    "dbt Analytics Engineering on Athena",
    filename="docs/architecture",
    show=False,
    direction="LR",
    graph_attr=graph_attrs,
    node_attr=node_attrs,
):
    ci = GithubActions("CI\n(fmt, compile, tests)")

    with Cluster("dbt project (code)"):
        dbt = Dbt("seed -> run -> test")

    with Cluster("Glue Data Catalog"):
        bronze = GlueDataCatalog("raw_orders\n(bronze)")
        silver = GlueDataCatalog("stg_orders\n(silver view)")
        gold = GlueDataCatalog("marts\n(gold Parquet)")

    lake = S3("S3 lake")
    athena = Athena("Athena engine")

    ci >> Edge(label="dbt build") >> dbt
    dbt >> Edge(label="compiles SQL") >> athena
    athena >> bronze >> silver >> gold
    gold >> Edge(style="dashed", label="Parquet") >> lake
