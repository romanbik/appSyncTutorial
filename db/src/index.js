const AWS = require('aws-sdk');

(async () => {
	try {
		const ssm = new AWS.SSM({
			accessKeyId: process.env.ACCESS_KEY_ID,
			secretAccessKey: process.env.SECRET_ACCESS_KEY,
			region: process.env.AWS_REGION,
		});
		const parameter = await ssm.getParameter({
			Name: process.env.DB_SECRET_NAME,
			WithDecryption: true
		}).promise();
		const data = JSON.parse(parameter.Parameter.Value);
		console.log(data); // prints the json from above
		/*
			{
				key: "this-is-a-secret-key",
				secret: "this-is-a-key-secret"
			}
			*/
	} catch (error) {

	}

})();


