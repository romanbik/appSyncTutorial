DROP SCHEMA IF EXISTS uuids;
CREATE SCHEMA uuids;
USE uuids;

-- --- Creation of project table
-- CREATE TABLE IF NOT EXISTS project (
--   id INT AUTO_INCREMENT PRIMARY KEY,
--   title varchar(200) NOT NULL,
--   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--   updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    
--   PRIMARY KEY (id)
-- ) ENGINE=INNODB;

-- --- Creation of task table
-- CREATE TABLE IF NOT EXISTS task (
--   id INT AUTO_INCREMENT,
--   title varchar(200) NOT NULL,
--   description varchar(200),
--   projectId INT NOT NULL,
--   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--   updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    
--   PRIMARY KEY (id),
--   FOREIGN KEY (projectId)
--       REFERENCES project (id)
--       ON UPDATE RESTRICT ON DELETE CASCADE
-- ) ENGINE=INNODB;

-- --- Creation of sub_task table
-- CREATE TABLE IF NOT EXISTS sub_task (
--   id INT AUTO_INCREMENT,
--   title varchar(200) NOT NULL,
--   description varchar(200),
--   taskId INT NOT NULL,
--   created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--   updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    
--   PRIMARY KEY (id),
--   FOREIGN KEY (taskId)
--       REFERENCES task (id)
--       ON UPDATE RESTRICT ON DELETE CASCADE
-- ) ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS project (
  id BINARY(16),
  title varchar(200) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    
  PRIMARY KEY (id)
) ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS task (
  id BINARY(16),
  title varchar(200) NOT NULL,
  description varchar(200),
  projectId BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    
  PRIMARY KEY (id),
  FOREIGN KEY (projectId)
      REFERENCES project (id)
      ON UPDATE RESTRICT ON DELETE CASCADE
) ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS sub_task (
  id BINARY(16),
  title varchar(200) NOT NULL,
  description varchar(200),
  taskId BINARY(16) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    
  PRIMARY KEY (id),
  FOREIGN KEY (taskId)
      REFERENCES task (id)
      ON UPDATE RESTRICT ON DELETE CASCADE
) ENGINE=INNODB;
