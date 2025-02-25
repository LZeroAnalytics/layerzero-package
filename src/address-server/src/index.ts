import express from 'express';
import cors from 'cors';

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());

// Read the env variables and convert them to arrays (trim any extra spaces)
const dvnAddresses: string[] = process.env.DVN_ADDRESSES
    ? process.env.DVN_ADDRESSES.split(',').map(addr => addr.trim())
    : [];

const executorAddresses: string[] = process.env.EXECUTOR_ADDRESSES
    ? process.env.EXECUTOR_ADDRESSES.split(',').map(addr => addr.trim())
    : [];

app.get('/addresses', (req, res) => {
    res.json({
        dvns: dvnAddresses,
        executors: executorAddresses
    });
});

app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});
