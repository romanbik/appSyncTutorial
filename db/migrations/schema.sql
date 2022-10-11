CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

SELECT uuid_generate_v4();

--- Creation of project table
CREATE TABLE IF NOT EXISTS project (
  id uuid DEFAULT uuid_generate_v4(),
  title varchar(200) NOT NULL,
  PRIMARY KEY (id)
);

--- Creation of task table
CREATE TABLE IF NOT EXISTS task (
  id uuid DEFAULT uuid_generate_v4(),
  title varchar(200) NOT NULL,
  description varchar(200),
  projectId uuid NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_client
      FOREIGN KEY(projectId) 
	  REFERENCES project(id)
);

--- Creation of sub_task table
CREATE TABLE IF NOT EXISTS sub_task (
  id uuid DEFAULT uuid_generate_v4(),
  title varchar(200) NOT NULL,
  description varchar(200),
  taskId uuid NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_client
      FOREIGN KEY(taskId) 
	  REFERENCES task(id)
);
