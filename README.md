# AppSync Tutorial

# Table of Contents

- [AppSync Tutorial](#appsync-tutorial)
- [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Techstack](#techstack)
  - [Usage](#usage)
  - [Architecture](#architecture)
  - [Project structure](#project-structure)
- [Code](#code)
  - [GraphQl Schema](#graphql-schema)
  - [Main (AppSync)](#main-appsync)
  - [Database (AWS Aurora)](#database-aws-aurora)
  - [Resolvers](#resolvers)
    - [Terraform file](#terraform-file)
    - [VTL files](#vtl-files)
- [Deployment](#deployment)
- [Testing](#testing)
- [Conclusion](#conclusion)

---

## Introduction

In this tutorial we will implement GraphQL Api using **AWS AppSync** and with **Aurora Serverless** as data source. It is important to note that our approach excludes creation of ANY backend services, all logic will be implemented inside AppSync. Also as IaC tool we will use Terraform. The business idea of the api will be simple app with project and tasks, every task can have multiply sub-tasks also.

---

## Techstack

- [AWS AppSync](https://aws.amazon.com/ru/appsync/) - provides a robust, scalable GraphQL interface for application developers to combine data from multiple sources, including Amazon DynamoDB, AWS RDS, AWS Lambda, and HTTP APIs.
- [AWS Aurora Serverless](https://aws.amazon.com/rds/aurora/serverless/) - is an on-demand, autoscaling configuration for Amazon Aurora. It automatically starts up, shuts down, and scales capacity up or down based on your application's needs. You can run your database on AWS without managing database capacity.
- [Terraform](https://www.terraform.io/) - is an infrastructure as code (IaC) tool that allows you to build, change, and version infrastructure safely and efficiently. This includes both low-level components like compute instances, storage, and networking, as well as high-level components like DNS entries and SaaS features.

---

## Usage

Download the project
`git clone https://github.com/romanbik/appSyncTutorial.git`

In the root folder run

`terraform init` initializes a working directory containing Terraform configuration files
`terraform plan` shows changes required by the current configuration
`terraform apply` create or update infrastructure

run migration file located in /db onside AWS query editor to create tables

---

## Architecture

So the main goal of project will be provide GraphQl Api for **Clients**. After **Client** send **Operation** - query (read-only fetch), mutation (write followed by a fetch), or subscription (long-lived requests that receive data in response to events), **App Sync** will proceed it to **Resolvers** that first querying **Aurora Database** and after it handle db response. Then **App Sync** will return requested data to the **Client** as **Action** - this action is a notification to connected subscribers, which is the result of a mutation. Clients become subscribers through a handshake process following a GraphQL subscription.

![picture alt](appsync.drawio.png "Architecture")

---

## Project structure

```
AppSync Tutorial
.
|-- ./LICENSE
|-- ./util.tf                           // terrafrom file for util resources.
|-- ./output.tf
|-- ./db
|   `-- ./db/migrations
|       `-- ./db/migrations/schema.sql  // migration file
|-- ./variables.tf                      // terraform vars definition
|-- ./db.tf                             // database definition
|-- ./aim.tf                            // AIM roles and policies definition
|-- ./api                               // VTL templates
|   `-- ./api/mapping-templates
|       |-- ./api/mapping-templates/default.request.vtl
|       |-- ./api/mapping-templates/default.response.vtl
|       |-- ./api/mapping-templates/project
|       |   |-- ./api/mapping-templates/project/getAll
|       |   |-- ./api/mapping-templates/project/update
|       |   |-- ./api/mapping-templates/project/getById
|       |   |   |-- ./api/mapping-templates/project/getById/project.request.vtl
|       |   |   `-- ./api/mapping-templates/project/getById/project.response.vtl
|       |   |-- ./api/mapping-templates/project/create
|       |   |   `-- ./api/mapping-templates/project/create/createProject.request.vtl
|       |   `-- ./api/mapping-templates/project/delete
|       |       |-- ./api/mapping-templates/project/delete/deleteProject.response.vtl
|       |       `-- ./api/mapping-templates/project/delete/deleteProject.request.vtl
|       `-- ./api/mapping-templates/task
|           |-- ./api/mapping-templates/task/delete
|           |-- ./api/mapping-templates/task/getAll
|           |-- ./api/mapping-templates/task/create
|           |   `-- ./api/mapping-templates/task/create/createTask.request.vtl
|           `-- ./api/mapping-templates/task/getById
|               |-- ./api/mapping-templates/task/getById/task.response.vtl
|               `-- ./api/mapping-templates/task/getById/task.request.vtl
|-- ./schema.graphql                      // GraphQL schema
|-- ./resolvers.tf                        // Resolvers definition
|-- ./main.tf                             // Main resource terraform file
`-- ./README.md%
```

---

# Code

## GraphQl Schema

A GraphQl Schema is a core of any GraphQl server. This schema defines all available functionality. Inside this schema we should describe our data types and let say methods. Where **Queries** are methods to **retrieve** data and **Mutations** are for modifying it (create, update, delete).

```graphql
type Mutation {
  createProject(title: String!): Project
  updateProject(id: ID, tittle: String): Project
  deleteProject(id: ID): Project
  createTask(input: TaskInput): Task
}

type Project {
  id: ID!
  title: String!
  tasks: [Task]
}

type Query {
  project(id: ID!): Project
  # Get a single value of type 'Task' by primary key.
  task(id: ID!): Task
  # Get an array of type 'Task'.
  tasks(orderBy: TasksOrderBY): [Task]
}

type SubTask {
  id: ID!
  title: String!
  description: String
  task: Task!
}

type Task {
  id: ID!
  title: String!
  description: String
  project: Project!
}

input TaskInput {
  id: ID!
  title: String!
  description: String!
  projectId: ID!
}

enum TasksOrderBY {
  ID_DESC
  ID_ASC
}

schema {
  query: Query
  mutation: Mutation
}
```

## Main (AppSync)

First We need to create main terraform file to bootstrap provisioning. Provide AWS and define AppSync, data sources, api key, GraphQl schema.
Inside appsync resource definition we describe name, schema (path to the graphql schema file), authentication type. Also we need to set explicit dependency to tell Terraform that AppSync resource must be created after db creation.
Then we need to describe **aws_appsync_graphql_api** and **aws_appsync_datasource**.
Datasource is a persistent storage system or a trigger, along with credentials for accessing that system or trigger. Your application state is managed by the system or trigger defined in a data source. Examples of data sources include NoSQL databases, relational databases, AWS Lambda functions, and HTTP APIs. We use rds as data source so as type we set "RELATIONAL_DATABASE". Inside **relational_database_config** we describe **http_endpoint_config** specify db name, db cluster and SSM arn's.
Because in this resources we describe dependencies via implicit linking (for ex. api_id or db_cluster_identifier properties).
You can note that service role for datasource also specified here. We will create role for it later.

**Here is resource definition.**
file: `main.tf`

```tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.30"
    }
  }
}

# Set the AWS credentials profile and region you want to publish to.
provider "aws" {
  region                   = var.region
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
}


# --- AppSync Setup ---

# Create the AppSync GraphQL api.
resource "aws_appsync_graphql_api" "appsync" {
  name                = "${var.prefix}_appsync"
  schema              = file("schema.graphql")
  authentication_type = "API_KEY"
  depends_on          = [aws_rds_cluster.cluster]

}

# Create the API key.
resource "aws_appsync_api_key" "appsync_api_key" {
  api_id = aws_appsync_graphql_api.appsync.id
}

resource "aws_appsync_datasource" "rds" {
  api_id           = aws_appsync_graphql_api.appsync.id
  name             = "rds"
  service_role_arn = aws_iam_role.appsync-role.arn
  type             = "RELATIONAL_DATABASE"
  relational_database_config {
    http_endpoint_config {
      db_cluster_identifier = aws_rds_cluster.cluster.arn
      aws_secret_store_arn  = aws_secretsmanager_secret.db-pass.arn
      database_name         = aws_rds_cluster.cluster.database_name
    }
  }
}
```

---

## Database (AWS Aurora)

Secondly let's define Aurora Cluster resource and secret manage to store user and password for it. Inside AWS Secrets MAnager we will store all db credentioal data and its host, engine, name.
As database we choice Aurora Serverless v1 with 5.7.mysql_aurora.2.07.1, because only this version has Web Api which enable the SQL HTTP endpoint, a connectionless Web Service API for running SQL queries against this database. When the SQL HTTP endpoint is enabled, you can also query your database from inside the RDS console (these features are free to use).

**Here is resource definition.**
file: `db.tf`

```tf
locals {
  resource_name_prefix = var.project
}

resource "aws_secretsmanager_secret" "db-pass" {
  name = "${local.resource_name_prefix}-mysql-secret-${random_string.secret_id.result}"
}

resource "aws_secretsmanager_secret_version" "db-pass-val" {
  secret_id = aws_secretsmanager_secret.db-pass.id
  secret_string = jsonencode(
    {
      username      = aws_rds_cluster.cluster.master_username
      password      = aws_rds_cluster.cluster.master_password
      engine        = "mysql"
      host          = aws_rds_cluster.cluster.endpoint
      database_name = "appsync"
    }
  )
}

resource "aws_rds_cluster" "cluster" {
  engine               = "aurora-mysql"
  engine_version       = "5.7.mysql_aurora.2.07.1"
  engine_mode          = "serverless"
  database_name        = "appsync"
  master_username      = "admin"
  master_password      = random_password.db_master_pass.result
  enable_http_endpoint = true
  skip_final_snapshot  = true
  scaling_configuration {
    min_capacity = 1
  }
  lifecycle {
    # RDS auto-upgrades the version
    # so this tells Terraform not to downgrade it the next apply
    ignore_changes = [
      engine_version,
    ]
  }
}
```

---

## Resolvers

Definig reolvers to handles GraphQl requests. A function that converts the GraphQL payload to the underlying storage system protocol and executes if the caller is authorized to invoke it. Resolvers are comprised of request and response mapping templates, which contain transformation and execution logic.

### Terraform file

First we need to descibe our resolver resources, so Terraform will create it. Inside each aws_appsync_resolver resource block we specify AppSync Api id, resolvers type: Query or mutation, field with wich we want to associate this resolver and data source arn.
Also we should add pathes to request and response temppate files.

file: `resolvers.tf`

```tf
# Create resolvers using the velocity templates

resource "aws_appsync_resolver" "createProject_resolver" {
  api_id      = aws_appsync_graphql_api.appsync.id
  type        = "Mutation"
  field       = "createProject"
  data_source = aws_appsync_datasource.rds.name

  request_template  = file("./api/mapping-templates/project/create/createProject.request.vtl")
  response_template = file("./api/mapping-templates/default.response.vtl")
}

resource "aws_appsync_resolver" "delete_resolver" {
  api_id      = aws_appsync_graphql_api.appsync.id
  type        = "Mutation"
  field       = "deleteProject"
  data_source = aws_appsync_datasource.rds.name

  request_template  = file("./api/mapping-templates/project/delete/deleteProject.request.vtl")
  response_template = file("./api/mapping-templates/project/delete/deleteProject.response.vtl")
}

resource "aws_appsync_resolver" "getProject_resolver" {
  api_id      = aws_appsync_graphql_api.appsync.id
  type        = "Query"
  field       = "project"
  data_source = aws_appsync_datasource.rds.name

  request_template  = file("./api/mapping-templates/project/getById/project.request.vtl")
  response_template = file("./api/mapping-templates/project/getById/project.response.vtl")
}

resource "aws_appsync_resolver" "getTask_resolver" {
  api_id      = aws_appsync_graphql_api.appsync.id
  type        = "Query"
  field       = "task"
  data_source = aws_appsync_datasource.rds.name

  request_template  = file("./api/mapping-templates/task/getById/task.request.vtl")
  response_template = file("./api/mapping-templates/task/getById/task.response.vtl")
}

resource "aws_appsync_resolver" "createTask_resolver" {
  api_id      = aws_appsync_graphql_api.appsync.id
  type        = "Mutation"
  field       = "createTask"
  data_source = aws_appsync_datasource.rds.name

  request_template  = file("./api/mapping-templates/task/create/createTask.request.vtl")
  response_template = file("./api/mapping-templates/default.response.vtl")
}
```

### VTL files

Since we will not use the backend, we will describe all the logi?? inside mapping templates.
The request mapping template is written with the [Apache Velocity templating language (VTL)](https://velocity.apache.org/engine/1.7/vtl-reference.html) and translates a GraphQL request into a format that the data source can understand.

Quick Reference:

- $context.arguments: An object containing the arguments passed to the field in the GraphQL query.
- $context.identity: An object containing identity information for the currently logged in user.
- $context.result: The value returned by the resolver from the data source. The shape of this object \* depends on the data source and operation.
- $util.toJson(): Serialize an object as JSON. This is often used with $context.arguments. For example, $util.toJson($context.arguments).
- $util.autoId(): Automatically generate a v4 UUID on the server.
- // ## A single-line comment \*\*

**Here is createProject request definition.**
file: `/api/mapping-templates/project/create/createProject.request.vtl`

```vtl
#set($id=$utils.autoId())

{
    "version": "2018-05-29",
    "statements": [
        "insert into project(id,title) values (UNHEX(REPLACE('$id','-','')),'$ctx.args.title')",
        "select * from project WHERE id = UNHEX(REPLACE('$id','-',''))"
    ],
}
```

The $id is an auto-generated identifier that AppSync generates in the first line. Then both statements can use it to identify the item.

This structure is the usual approach for implementing insertion:

- Generate the ID in the resolver
- Insert the row in the first statement
- Then retrieve in the second

**Here is a createProject response definition.**

The SQL statements will execute sequentially, based on the order in the **statements** array. The results will come back in the same order. Since this is a mutation, we run a select statement after the insert to retrieve the committed values in order to populate the GraphQL response mapping template.
In the **response mapping template** section, add the following template:
file: `/api/mapping-templates/default.response.vtl`

```vtl
## Raise a GraphQL field error in case of a datasource invocation error
#if($ctx.error)
    $utils.error($ctx.error.message, $ctx.error.type)
#end
$utils.toJson($utils.rds.toJsonObject($ctx.result)[1][0])
```

Because the statements have two SQL queries, we need to specify the second result in the matrix that comes back from the database with: $utils.rds.toJsonString($ctx.result))[1][0]).

**Let???s use the same approach to create a ???createTask??? resolver:**
file: `/api/mapping-templates/task/create/createTask.request.vtl`
For task creation we need id wich will be autogenerated and title, description and projectId, that will be received from arguments.

```vtl
#set($id=$utils.autoId())
#set($title = $ctx.args.input.title)
#set($description = $ctx.args.input.description)
#set($projectId = $ctx.args.input.projectId)

{
    "version": "2018-05-29",
    "statements": [
        "insert into task values (UNHEX(REPLACE('$id','-','')),'$title','$description',UNHEX(REPLACE('$projectId','-','')))",
        "select * from task WHERE id = UNHEX(REPLACE('$id','-',''))"
    ]
}
```

As response template - default response template will be used.

Next step will be creating a query to retrieve one task and the project to which it is associated.

**Request mapping template:**
file: `/api/mapping-templates/task/getById/task.request.vtl`

```vtl
#**
Select statement for a relational database data source
*#
#set($id=$ctx.args.id)
{
    "version": "2018-05-29",
    "statements": [
        "select p.title 'projectTitle', t.* from task as t INNER JOIN project as p ON t.projectId = p.id where t.id = UNHEX(REPLACE('$id','-','')"
    ]
}
```

In this case we create a JOIN statement to retrieve a task project. Don???t forget to add alias for project title field as our task entity also has this field.

**Response mapping template:**
file: `/api/mapping-templates/task/getById/task.response.vtl`

```vtl
## Raise a GraphQL field error in case of a datasource invocation error
#if($ctx.error)
    $util.error($ctx.error.message, $ctx.error.type)
#end
#set($output = $utils.rds.toJsonObject($ctx.result)[0][0])
#set($output.project = {
"id": $output.get('projectId'),
"title": $output.get('projectTitle')
})
$util.toJson($output)
```

As you can see here we are also populating a project object.

We received our task object and project to which this task belongs.
Now we can retrieve project data and all corresponding tasks. For it let also create a resolver.
Here we have two sql statements one for retrieving project and another for tasks data

**Request mapping template:**

file: `/api/mapping-templates/project/getById/project.request.vtl`

```vtl
#**
Select statement for a relational database data source
*#
#set($id=$ctx.args.id)

{
    "version": "2018-05-29",
    "statements": [
        "select * from project where id = UNHEX(REPLACE('$id','-','')",
        "select * from task where projectId = UNHEX(REPLACE('$id','-','')"
    ]
}
```

Inside response template we firstly set project data and after all tasks corresponding to it.

**Response mapping template:**
file: `/api/mapping-templates/project/getById/project.response.vtl`

```vtl
## Raise a GraphQL field error in case of a datasource invocation error
#if($ctx.error)
    $util.error($ctx.error.message, $ctx.error.type)
#end
#set($output = $utils.rds.toJsonObject($ctx.result)[0][0])
## Make sure to handle instances where field are null
## or don't exist acording to your business logic
#set($output.tasks = $utils.rds.toJsonObject($ctx.result)[1])
$util.toJson($output)
```

---

# Deployment

Just run `terraform init`, then `terraform plan` to see what resource will be create, destroyed or modified. And finally run `terraform apply` to deploy everything.

_Note: After database creation, go to AWS RDS console, select your db and inside **Query Editor** run migration **schema.sql** script to create tables._

![picture alt](tables.png "Tables creation")

---

# Testing

To test our Api we can use AppSync queries tab.

![picture alt](testing.png "Testing AppSync api")

---

# Conclusion

That it! We managed to create AppSync Api, with Aurora Serverless as data source, create resolvers to retrieve and modify data. It It may have seemed like a lot, but in reality we have only several Terraform files that will create all needed infrastructure. It is way more easier and faster than to create it all manualy and destroy after.

Though it is possible to construct your AppSync Api without using any backend app or lambdas, it is recommended to omit this Velocity Templates based approach. You???re unlikely to work with it anywhere else unless you???re maintaining Java-based web applications from the beginning of the 21st century. Velocity Templates are hard to test and powerful enough to ruin your application???s logic. Also in this tutorial we didn???t implement any query sanitation, but keep in mind the query injection problem too.
AWS Appsync doesn???t compare to your if you are building mobile or web applications outside the AWS ecosystem. In this case, consider other managed GraphQL engines:

- [Hasura](https://hasura.io/) (open-source, Postgres Based)
- [Apollo](https://www.apollographql.com/docs/apollo-server/) (open-source; a managed version)
- [Prisma](https://www.prisma.io/v5) (open-source; a managed version)
