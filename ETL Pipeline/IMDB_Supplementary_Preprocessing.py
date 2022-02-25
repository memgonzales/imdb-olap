import pandas as pd
import sys

movies_df = pd.read_csv(sys.stdin)

split_dates_df = movies_df
temp = split_dates_df[sys.argv[1]].str.split('[-/]', expand = True)
split_dates_df["year"] = temp[2]
split_dates_df["month"] = temp[1]
split_dates_df["day"] = temp[0]

split_genres_df = movies_df.drop(['year', 'month', 'day'], axis = 1)

split_dates_df.loc[split_dates_df.day.astype(int) >= 1894, 'year'] = split_dates_df.day
split_dates_df.loc[split_dates_df.day.astype(int) >= 1894, 'day'] = '01'

split_dates_df['year'].replace(to_replace=[None], value='01', inplace=True)
split_dates_df['month'].replace(to_replace=[None], value='01', inplace=True)
split_dates_df['day'].replace(to_replace=[None], value='01', inplace=True)

split_dates_df = split_dates_df.drop(sys.argv[1], axis = 1)
split_dates_df[sys.argv[1]] = split_dates_df['year'] + '-' + split_dates_df['month'] + '-' + split_dates_df['day']
split_dates_df = split_dates_df.drop(['year', 'month', 'day'], axis = 1)

split_countries_df = split_dates_df
split_countries_df = split_countries_df.assign(country=split_countries_df[sys.argv[2]].str.split(',')).explode(sys.argv[2])

split_genres_df = split_countries_df
split_genres_df = split_genres_df.assign(genre=split_genres_df[sys.argv[3]].str.split(',')).explode(sys.argv[3])

split_genres_df.to_csv(sys.stdout, index=False)  

