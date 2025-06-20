

1. How many pizzas were ordered?
2. How many unique customer orders were made?
3. How many successful orders were delivered by each rider?
4. How many of each type of pizza was delivered?
5. How many 'Paneer Tikka' and 'Veggie Delight' pizzas were ordered by each customer?
6. What was the maximum number of pizzas delivered in a single order?
7. For each customer, how many delivered pizzas had at least 1 change (extras or exclusions) and how many had no changes?
8. How many pizzas were delivered that had both exclusions and extras?
9. What was the total volume of pizzas ordered for each hour of the day?
10. What was the volume of orders for each day of the week?

11. How many riders signed up for each 1-week period starting from 2023-01-01?
12. What was the average time in minutes it took for each rider to arrive at Pizza Delivery HQ to pick up the order?
13. Is there any relationship between the number of pizzas in an order and how long it takes to prepare?
14. What was the average distance traveled for each customer?
15. What was the difference between the longest and shortest delivery durations across all orders?
16. What was the average speed (in km/h) for each rider per delivery? Do you notice any trends?
17. What is the successful delivery percentage for each rider?

18. What are the standard ingredients for each pizza?
19. What was the most commonly added extra (e.g., Mint Mayo, Corn)?
20. What was the most common exclusion (e.g., Cheese, Onions)?
21. Generate an order item for each record in the `customer_orders` table in the format:

    * Paneer Tikka
    * Paneer Tikka - Exclude Corn
    * Paneer Tikka - Extra Cheese
    * Veggie Delight - Exclude Onions, Cheese - Extra Corn, Mushrooms
22. Generate an alphabetically ordered, comma-separated ingredient list for each pizza order, using "2x" for duplicates.

    * Example: "Paneer Tikka: 2xCheese, Corn, Mushrooms, Schezwan Sauce"
23. What is the total quantity of each topping used in all successfully delivered pizzas, sorted by most used first?


24. If a 'Paneer Tikka' pizza costs ₹300 and a 'Veggie Delight' costs ₹250 (no extra charges), how much revenue has Pizza Delivery India generated (excluding cancellations)?

25. What if there’s an additional ₹20 charge for each extra topping?

26. Cheese costs ₹20 extra — apply this specifically where Cheese is added as an extra.

27. Design a new table for customer ratings of riders. Include:

    * rating_id, order_id, customer_id, rider_id, rating (1-5), comments (optional), rated_on (DATETIME)

    Example schema:

    ```sql
    CREATE TABLE pizza_delivery_india.rider_ratings (
      rating_id INT IDENTITY PRIMARY KEY,
      order_id INT,
      customer_id INT,
      rider_id INT,
      rating INT CHECK (rating BETWEEN 1 AND 5),
      comments NVARCHAR(255),
      rated_on DATETIME
    );
    ```

28. Insert sample data into the ratings table for each successful delivery.

29. Join data to show the following info for successful deliveries:

    * customer_id
    * order_id
    * rider_id
    * rating
    * order_time
    * pickup_time
    * Time difference between order and pickup (in minutes)
    * Delivery duration
    * Average speed (km/h)
    * Number of pizzas in the order

30. If Paneer Tikka is ₹300, Veggie Delight ₹250, and each rider is paid ₹2.50/km, what is Pizza Delivery India's profit after paying riders?



31. If the owner wants to add a new “Supreme Indian Pizza” with all available toppings, how would the existing design support that? Provide an example `INSERT`:


