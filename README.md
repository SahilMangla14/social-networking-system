# social-networking-system

![ER-Diagram](/docs/er-diagram.png)

## Getting Started

Clone the repository

```
git clone https://github.com/Karanraj06/social-networking-system.git
```

Create a `.env` file and add the `DATABASE_URL`

```
cp .env.example .env
```

Go to the `app` directory and run the python files as following:

```
cd app
python crud.py
python seed.py
```

Start the Fast API server

```
uvicorn main:app --reload
```

Open http://localhost:8000/docs to view the API documentation.

## Database Insider

Clone the `prisma` branch

```
git clone https://github.com/Karanraj06/social-networking-system prisma
```

Start prisma studio

```
npx prisma studio
or
bunx prisma studio
```

Open http://localhost:5555 to view it in your browser.

## Contributors
Atharva Suhas Mulay ([@AtharvaMulay25](https://github.com/AtharvaMulay25))<br>
Karanraj Mehta ([@Karanraj06](https://github.com/Karanraj06))<br>
Sahil Mangla ([@SahilMangla14](https://github.com/SahilMangla14))<br>
Harsh Raj Srivastava ([@Harsh290803](https://github.com/Harsh290803))