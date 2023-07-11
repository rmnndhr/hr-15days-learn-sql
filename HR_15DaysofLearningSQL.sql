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
Continue building temp tables with unique hacker(s),who has been submitting daily since day 1.
Do so by joining previous day's table with common hackers, who submitted both days. 
Previous day's table only includes hacker(s), who has been submitting daily since day 1 
up to that day.
*/
mar2 AS (
	SELECT s.submission_date, s.hacker_id
	FROM public.submissions AS s
	INNER JOIN mar1
	ON s.hacker_id = mar1.hacker_id AND s.submission_date = '2016-03-02'	
),
mar3 AS (
	SELECT s.submission_date, s.hacker_id
	FROM public.submissions AS s
	INNER JOIN mar2
	ON s.hacker_id = mar2.hacker_id AND s.submission_date = '2016-03-03'
),
mar4 AS (
	SELECT s.submission_date, s.hacker_id
	FROM public.submissions AS s
	INNER JOIN mar3
	ON s.hacker_id = mar3.hacker_id AND s.submission_date = '2016-03-04'
),
mar5 AS (
	SELECT s.submission_date, s.hacker_id
	FROM public.submissions AS s
	INNER JOIN mar4
	ON s.hacker_id = mar4.hacker_id AND s.submission_date = '2016-03-05'
),
mar6 AS (
	SELECT s.submission_date, s.hacker_id
	FROM public.submissions AS s
	INNER JOIN mar5
	ON s.hacker_id = mar5.hacker_id AND s.submission_date = '2016-03-06'
),
/*
Merge each month's temp tables to get the unique hackers corresponding to each day.
This table only inlcudes unique hacker_id that submited daily since day 1 up to that day.
*/
t1 AS (
	SELECT * 
	FROM mar1 
	UNION SELECT * 
	FROM mar2
	UNION SELECT * 
	FROM mar3
	UNION SELECT * 
	FROM mar4
	UNION SELECT * 
	FROM mar5
	UNION SELECT * 
	FROM mar6
	ORDER BY 1
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