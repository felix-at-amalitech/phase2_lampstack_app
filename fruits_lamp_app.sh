#!/bin/bash

# Update system packages
sudo yum update -y

# Install Apache (httpd), PHP, PHP MySQL Native Driver, MariaDB client, and AWS CLI
sudo yum install -y httpd php php-mysqlnd mariadb awscli

# Start Apache web server
sudo systemctl start httpd

# Enable Apache to start on boot
sudo systemctl enable httpd

# Retrieve database credentials from SSM Parameter Store
DB_USER=$(aws ssm get-parameter --name "/lamp/db/username" --region eu-west-1 --query Parameter.Value --output text)
DB_PASS=$(aws ssm get-parameter --name "/lamp/db/password" --region eu-west-1 --with-decryption --query Parameter.Value --output text)

# Drop the existing table if it exists to ensure a clean slate for schema update
mysql -h lampdb.czaiaq68azf6.eu-west-1.rds.amazonaws.com -u $DB_USER -p$DB_PASS lampdb -e "DROP TABLE IF EXISTS healthy_fruits;"

# Create the healthy_fruits table with the new 'benefits' column
mysql -h lampdb.czaiaq68azf6.eu-west-1.rds.amazonaws.com -u $DB_USER -p$DB_PASS lampdb -e "CREATE TABLE healthy_fruits (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    benefits TEXT
);"

# Create the index.php file with HTML and PHP content using a heredoc
cat <<EOF > /var/www/html/index.php
<html>
<head>
    <title>Healthy Ghanaian Fruits</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f4f4f4; color: #333; }
        h1, h2 { color: #0056b3; }
        table {
            width: 80%;
            border-collapse: collapse;
            margin-top: 20px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            background-color: #fff;
        }
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #e9e9e9;
            color: #555;
            font-weight: bold;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        p {
            margin: 5px 0;
        }
        .error-message {
            color: red;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <h1>Welcome to the Healthy Ghanaian Fruits App!</h1>
    <h2>Fruits in Season:</h2>
    <table>
        <thead>
            <tr>
                <th>Fruit</th>
                <th>Benefits</th>
            </tr>
        </thead>
        <tbody>
            <?php
            // Establish database connection using SSM-retrieved credentials
            \$conn = new mysqli('lampdb.czaiaq68azf6.eu-west-1.rds.amazonaws.com', '$DB_USER', '$DB_PASS', 'lampdb');

            // Check for connection errors
            if (\$conn->connect_error) {
                echo '<tr><td colspan="2" class="error-message">Connection failed: ' . \$conn->connect_error . '</td></tr>';
            } else {
                // Query the database for fruit names and their benefits
                \$result = \$conn->query('SELECT name, benefits FROM healthy_fruits');

                // Check if there are results
                if (\$result && \$result->num_rows > 0) {
                    // Loop through results and display in table rows
                    while(\$row = \$result->fetch_assoc()) {
                        echo '<tr><td>' . \$row['name'] . '</td><td>' . \$row['benefits'] . '</td></tr>';
                    }
                } else {
                    // Message if no fruits are found or query fails
                    echo '<tr><td colspan="2">No healthy fruits found in the database.</td></tr>';
                }
                // Close the database connection
                \$conn->close();
            }
            ?>
        </tbody>
    </table>
</body>
</html>
EOF

# Insert healthy fruits with their associated benefits into the table
mysql -h lampdb.czaiaq68azf6.eu-west-1.rds.amazonaws.com -u $DB_USER -p$DB_PASS lampdb -e "
INSERT INTO healthy_fruits (name, benefits) VALUES
('Pineapple', 'Rich in Vitamin C and manganese, contains bromelain for anti-inflammatory properties.'),
('Mango', 'Packed with Vitamin C, Vitamin A, and fiber, contains various antioxidants.'),
('Banana', 'Excellent source of potassium, Vitamin B6, and Vitamin C, provides energy.'),
('Plantain', 'Starchy, good source of complex carbohydrates, vitamins, and minerals, often cooked.'),
('Soursop (Aluguntugui)', 'High in Vitamin C, known for potential antioxidant and anti-inflammatory properties.'),
('African Star Apple (Alasa)', 'Good source of calcium and Vitamin C, believed to aid digestion.'),
('Velvet Tamarind (Yooyi)', 'High in Vitamin C, iron, magnesium, and dietary fiber, tart-sweet.'),
('Guava', 'Rich in Vitamin C, dietary fiber, and antioxidants, supports immunity.'),
('Papaya', 'Rich in Vitamin C, Vitamin A, and the enzyme papain which aids digestion.');"