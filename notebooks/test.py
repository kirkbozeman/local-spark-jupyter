from pyspark.sql import SparkSession
from delta import *

# spark session
spark = SparkSession.builder \
    .master("yarn") \
    .config("spark.submit.deployMode", "client") \
    .appName("Test App") \
    .getOrCreate()

sc = spark.sparkContext
#sc

print(sc.getConf().getAll())