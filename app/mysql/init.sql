CREATE TABLE IF NOT EXISTS users(
    id int AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Deployments tracking table
CREATE TABLE IF NOT EXISTS deployments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    version VARCHAR(50) NOT NULL,
    environment VARCHAR(50) NOT NULL,
    deployed_by VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'success',
    deployed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- seed data

INSERT INTO users (name, email) VALUES 
    ('john jonah', 'johnjonah0866@gmail.com'),
    ('DevOps Bot', 'devops@system.local');


INSERT INTO deployments(version, environment, deployed_by, status)  VALUES 
        ('1.0.0', 'development', 'john jonah', 'sucess'),
        ('1.0.0', 'staging', 'John Jonah', 'success');

SELECT 'Database initialized successfully' AS message;       