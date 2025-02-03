--Завдання 1. Вивести всі дані з таблиці "employees".					
select *
from public.tech_int;

--Завдання 2. Вибрати імена та зарплати всіх працівників, які отримують більше 50000.					
select *
from public.tech_int
where salary > 50000;

--Завдання 3. Знайти кількість працівників в департаменті з ідентифікатором 10.					
select count(*)
from public.tech_int
where department_id = 10;

--Завдання 4. Вивести унікальні департаменти в яких працюють працівники з таблиці "departments".
select td.department_name
from public.tech_int_dep TD
inner join public.tech_int TT on td.department_id = tt.department_id
group by td.department_name 
;

--Завдання 5. Вивести загальну кількість працівників в кожному департаменті та середню зарплату.
select department_id, count (*) as emp_num, avg(salary) as av_sal
from public.tech_int
group by department_id
order by 1
;

--Завдання 6. Знайти працівника з найвищою зарплатою та вказати назву його департаменту department_name.				
select tt.department_id, td.department_name, tt.name
from public.tech_int tt
left join public.tech_int_dep td on td.department_id = tt.department_id
where salary = (select max(salary) from public.tech_int)
;

--Завдання 6. Знайти працівника з найвищою зарплатою та вказати назву його департаменту department_name.				
select tt.department_id, td.department_name, tt.name
from public.tech_int tt
left join public.tech_int_dep td on td.department_id = tt.department_id
order by salary desc 
limit 1
;	

--Завдання 7. Вивести загальну суму зарплат у кожному департаменті та відсортувати в порядку спадання.
select td.department_name, sum(salary) as total_salary
from public.tech_int tt
left join public.tech_int_dep td on td.department_id = tt.department_id
group by td.department_name
order by total_salary desc;

--Завдання 8. Знайти середню зарплату для працівників, найманих після 1 січня 2022 року.
select name, avg(salary) as avg_salary
from public.tech_int tt
where hire_date >='2022-01-01'
group by name;

--Завдання 9. Вивести топ-3 департаменти з найвищою середньою зарплатою.					
select td.department_name, avg(salary) as avg_salary
from public.tech_int tt
left join public.tech_int_dep td on td.department_id = tt.department_id
group by td.department_name
order by avg_salary desc
limit 3;

--Завдання 10. Вивести назву департаменту з другою найбільшою середньою зарплатнею.					
select td.department_name, avg(salary) as avg_salary
from public.tech_int tt
left join public.tech_int_dep td on td.department_id = tt.department_id
group by td.department_name
order by avg_salary desc 
limit 1 offset 1;

--Завдання 11. Вибрати імена працівників, які мають унікальні зарплати та працюють в IT-відділі.
select distinct tt.name, td.department_name, tt.salary
from public.tech_int tt
left join public.tech_int_dep td on td.department_id = tt.department_id
where td.department_name = 'IT'
and tt.salary in ( select salary from public.tech_int group by salary having count(*) = 1);




