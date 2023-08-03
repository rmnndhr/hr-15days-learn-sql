/*
Write a query to print total number of unique hackers who made at least 1
submission each day (starting on the first day of the contest), and find the 
hacker_id and name of the hacker who made maximum number of submissions 
each day. If more than one such hacker has a maximum number of submissions, 
print the lowest hacker_id. The query should print this information for each day of 
the contest, sorted by the date.
*******************
Assume that the end date of the contest was March 06, 2016.
Will need to add more temp tables for remainder of 15 days in March, 
or refactor code to easily calculate for more than 6 days.
*******************
*/

-- Build a temp table mar1 with unique hacker(s) who submitted that day
WITH mar1 AS (
	SELECT submission_date, hacker_id
	FROM public.submissions
	WHERE submission_date = '2016-03-01'
	GROUP BY 1, 2
	ORDER BY 1
),
/*
Build temp table with unique hacker(s),who has been submitting since day 1.
Do so by joining submissions table with only hackers that submitted on day 1.
Then, add a new column to show if the submittals skipped a day or more.
*/
mar15 AS (
	SELECT s2.submission_date, 
		   s2.hacker_id, 
		   s2.submission_date - LAG(s2.submission_date) OVER (PARTITION BY s2.hacker_id ORDER BY s2.hacker_id, s2.submission_date) AS lag_diff
	FROM mar1 AS s1
	INNER JOIN  public.submissions AS s2
	ON     s1.hacker_id = s2.hacker_id
	ORDER BY 2, 1
),
/*
Select only the hackers that haven't skipped a day (lag_diff = 1 if submitted daily & = 0 if multiple submissions on same day).
Select those with lag_diff IS NULL too since that includes submittals on Mar 1.
This table only inlcudes unique hacker_id that submited daily since day 1 up to that day.
*/
t1 AS (
	SELECT submission_date, hacker_id
	FROM mar15
	WHERE lag_diff IS NULL OR lag_diff <= 1
	ORDER BY 1, 2
),
/*
Generate a temp table to get hacker name and a total count of daily submission
per hacker per day.
*/
t2 AS (
    SELECT s.submission_date, s.hacker_id, h.name, COUNT(*) AS daily_subs
    FROM public.submissions AS s
    INNER JOIN public.hackers AS h
    ON s.hacker_id = h.hacker_id
    GROUP BY 1, 2, 3
    ORDER BY 1, 2
),
/*
Quering temp table, assign rank to each hacker_id based on who had the most submission 
any particular day. 
If more than 1 hacker had the most submission for that day, order rank by hacker_id ASC 
to select the hacker with the lowest hacker_id
*/
t3 AS (
	SELECT submission_date, hacker_id, name, daily_subs,
		NTILE(500) OVER (PARTITION BY submission_date ORDER BY daily_subs DESC, hacker_id) AS percentile
	FROM t2
)
/*
Join tables to count the total number of unique hackers submitting daily,
and only pull hackers who have RANK 1 on each given day.
*/
SELECT t3.submission_date, COUNT(*) AS hacker_count, t3.hacker_id, t3.name
FROM t3
INNER JOIN t1
ON t3.submission_date = t1.submission_date
WHERE percentile = 1
GROUP BY 1, 3, 4;