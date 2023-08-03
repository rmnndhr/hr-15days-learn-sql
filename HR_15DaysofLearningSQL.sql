/*
Write a query to print total number of unique hackers who made at least 1
submission each day (starting on the first day of the contest), and find the 
hacker_id and name of the hacker who made maximum number of submissions 
each day. If more than one such hacker has a maximum number of submissions, 
print the lowest hacker_id. The query should print this information for each day of 
the contest, sorted by the date.
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
Then, add a day column that shows the day of the month.
And add a new rank column to rank the submittals, using the same rank for multiple submissions on a single day.
*/
mar15 AS (
	SELECT s2.submission_date, 
		   s2.hacker_id,
		   DATE_PART('day',s2.submission_date) AS day_of_mar,  
		   DENSE_RANK() OVER (PARTITION BY s2.hacker_id ORDER BY s2.hacker_id, s2.submission_date) AS row_num
	FROM mar1 AS s1
	INNER JOIN public.submissions AS s2
	ON s1.hacker_id = s2.hacker_id
),
/*
Select only the hackers that haven't skipped a day (i.e. if rank < day of the month, means at least a day was skipped).
The first rank will be 1, which is the 1st of Mar, since each selection has submission = Mar 1.
This table only inlcudes unique hacker_id that submitted daily since day 1 up to that day.
*/
t1 AS (
	SELECT DISTINCT submission_date, hacker_id
	FROM mar15
	WHERE day_of_mar = row_num
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