require("dotenv").config();
const AWS = require('aws-sdk');
const { Sequelize } = require('sequelize');
const dbService = require("./db.service");

const secretsmanager = new AWS.SecretsManager({ apiVersion: '2017-10-17' });
let sequelize;

async function retrieveSSMValues() {
	try {
		const params = {
			SecretId: process.env.DB_SECRET_NAME
		};
		const secret = await secretsmanager.getSecretValue(params).promise();
		const data = JSON.parse(secret.SecretString);
		const { engine, host, password, username, database_name } = data;
		/*
			{
				key: "this-is-a-secret-key",
				secret: "this-is-a-key-secret"
			}
			*/
		const connection = {
			database: database_name,
			username,
			password,
			host: host || "localhost",
			dialect: engine,
		};
		return connection;
	} catch (error) {
		console.log(error);
	}
}


async function initDb() {
	try {
		const connection = await retrieveSSMValues();
		// const dummyConnection = {
		// 	database: 'database-1',
		// 	username: 'admin',
		// 	password: "Morison72",
		// 	host: "database-1.cluster-cqvivd8p94id.us-west-1.rds.amazonaws.com" || "localhost",
		// 	dialect: "mysql",
		// };

		console.log("connections =====>", connection);
		sequelize = new Sequelize(
			connection.database,
			connection.username,
			connection.password,
			{
				host: connection.host,
				dialect: connection.dialect,
				define: {
					freezeTableName: true
				},
				pool: {
					max: 10,
					min: 0,
					acquire: 65000,
					idle: 10000,
				},
				logging: console.log,
			},
		);
		const DB = dbService(sequelize, true).start();
	} catch (error) {
		console.log("Error during database initialization", error);
	}

};

initDb();

module.exports = sequelize;




