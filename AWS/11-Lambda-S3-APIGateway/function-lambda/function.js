exports.handler = async (event) => {
    console.log('Event: ', event);
    let responseMessage = 'Hello, World!';
    const method = event.requestContext?.http?.method || event.httpMethod;

    if (event.queryStringParameters && event.queryStringParameters['Name']) {
        responseMessage = 'Hello, ' + event.queryStringParameters['Name'] + '!';
    }

    if (method === 'POST' && event.body) {
        try {
            const body = JSON.parse(event.body);
            if (body.name) {
                responseMessage = 'Hello, ' + body.name + '!';
            }
        } catch (error) {
            return {
                statusCode: 400,
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    message: 'Invalid JSON request body',
                }),
            };
        }
    }

    const response = {
        statusCode: 200,
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            message: responseMessage
        }),
    };

    return response;
};
