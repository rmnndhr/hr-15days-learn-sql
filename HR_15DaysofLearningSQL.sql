WITH t1 AS (
	SELECT s.submission_date, s.hacker_id, h.name, COUNT(*) AS daily_subs
	FROM public.submissions AS s
	INNER JOIN public.hackers AS h
	ON s.hacker_id = h.hacker_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 2
)
t2 AS (
	SELECT submission_date, hacker_id, name, daily_subs,
		NTILE(500) OVER (PARTITION BY submission_date ORDER BY daily_subs DESC, hacker_id) AS percentile
	FROM t1
)
SELECT submission_date, hacker_id, name
FROM t2
WHERE percentile = 1;