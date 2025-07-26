import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns


df = pd.read_csv(r'C:\Users\Susheel\Desktop\Python\All case studies\Case Study 4 - Python Visualizations Case Study\SalesData.csv')


month_to_qtr = {
    'Jan': 'Q1', 'Feb': 'Q1', 'Mar': 'Q1',
    'Apr': 'Q2', 'May': 'Q2', 'Jun': 'Q2',
    'Jul': 'Q3', 'Aug': 'Q3', 'Sep': 'Q3',
    'Oct': 'Q4', 'Nov': 'Q4', 'Dec': 'Q4'
}
df['Qtr'] = df['Month'].map(month_to_qtr)


df_sales = pd.melt(df, 
                   id_vars=['AccountId', 'AccountName', 'Region', 'Division', 'City', 'State', 'Tier', 'Month', 'Qtr'],
                   value_vars=['Sales2015', 'Sales2016'],
                   var_name='Year',
                   value_name='Sales')
df_sales['Year'] = df_sales['Year'].str.extract(r'(\d+)').astype(int)

df_units = pd.melt(df,
                   id_vars=['AccountId', 'AccountName', 'Region', 'Division', 'City', 'State', 'Tier', 'Month', 'Qtr'],
                   value_vars=['Units2015', 'Units2016'],
                   var_name='Year',
                   value_name='Units')
df_units['Year'] = df_units['Year'].str.extract(r'(\d+)').astype(int)

df_target = pd.melt(df,
                    id_vars=['AccountId', 'AccountName', 'Region', 'Division', 'City', 'State', 'Tier', 'Month', 'Qtr'],
                    value_vars=['TargetAchevied2015', 'TargetAchevied2016'],
                    var_name='Year',
                    value_name='TargetAcheived')
df_target['Year'] = df_target['Year'].str.extract(r'(\d+)').astype(int)


df_long = df_sales.merge(df_units, on=['AccountId', 'AccountName', 'Region', 'Division', 'City', 'State', 'Tier', 'Month', 'Qtr', 'Year'])
df_long = df_long.merge(df_target, on=['AccountId', 'AccountName', 'Region', 'Division', 'City', 'State', 'Tier', 'Month', 'Qtr', 'Year'])

# 1. Compare Sales by region for 2016 vs 2015 (Bar chart)
region_sales = df_long.groupby(['Region', 'Year'])['Sales'].sum().unstack()

region_sales.plot(kind='bar', figsize=(10,6))
plt.title('Sales by Region: 2015 vs 2016')
plt.ylabel('Total Sales')
plt.xlabel('Region')
plt.legend(title='Year')
plt.tight_layout()
plt.show()

# 2. Pie chart: Sales by Region (2016)
sales_2016 = df_long[df_long['Year'] == 2016].groupby('Region')['Sales'].sum()
plt.figure(figsize=(8,8))
plt.pie(sales_2016, labels=sales_2016.index, autopct='%1.1f%%', startangle=140)
plt.title('Sales Contribution by Region (2016)')
plt.axis('equal')
plt.show()

# 3. Compare Total Sales by Region and Tier (2015 vs 2016)
pivot_sales = df_long.groupby(['Region', 'Tier', 'Year'])['Sales'].sum().unstack().reset_index()

plt.figure(figsize=(12,6))
sns.barplot(data=pivot_sales, x='Region', y=2015, hue='Tier')
plt.title('Sales by Region & Tier (2015)')
plt.ylabel('Sales')
plt.show()

plt.figure(figsize=(12,6))
sns.barplot(data=pivot_sales, x='Region', y=2016, hue='Tier')
plt.title('Sales by Region & Tier (2016)')
plt.ylabel('Sales')
plt.show()

# 4. East Region: States with sales decline in 2016
east = df_long[df_long['Region'] == 'East']
state_sales = east.groupby(['State', 'Year'])['Sales'].sum().unstack()
decline_states = state_sales[state_sales[2016] < state_sales[2015]]
print("States in East with sales decline in 2016:\n", decline_states)

# 5. High Tier: Divisions with unit decline in 2016
high_tier = df_long[df_long['Tier'] == 'High']
div_units = high_tier.groupby(['Division', 'Year'])['Units'].sum().unstack()
decline_divisions = div_units[div_units[2016] < div_units[2015]]
print("High Tier Divisions with Units Decline in 2016:\n", decline_divisions)

# 7. Compare Qtr wise sales (2015 vs 2016)
qtr_sales = df_long.groupby(['Qtr', 'Year'])['Sales'].sum().unstack()
qtr_sales.plot(kind='bar', figsize=(10,6))
plt.title('Quarterly Sales Comparison: 2015 vs 2016')
plt.ylabel('Total Sales')
plt.xlabel('Quarter')
plt.legend(title='Year')
plt.tight_layout()
plt.show()
# 8. Composition of Qtr-wise sales by Tier in Pie Charts
fig, axes = plt.subplots(2, 2, figsize=(14,10))
qtrs = ['Q1', 'Q2', 'Q3', 'Q4']

for ax, qtr in zip(axes.flat, qtrs):
    qtr_data = df_long[(df_long['Qtr'] == qtr) & (df_long['Year'] == 2016)]
    pie_data = qtr_data.groupby('Tier')['Sales'].sum()
    pie_data = pie_data[pie_data > 0]  # filter negative or zero values

    if not pie_data.empty:
        ax.pie(pie_data, labels=pie_data.index, autopct='%1.1f%%', startangle=140)
        ax.set_title(f'Sales Composition by Tier - {qtr} (2016)')
    else:
        ax.text(0.5, 0.5, 'No positive data', horizontalalignment='center', verticalalignment='center')
        ax.set_title(f'{qtr} (2016) - No data to plot')

plt.tight_layout()
plt.show()
