CREATE TABLE IF NOT EXISTS tasks (
  id         SERIAL PRIMARY KEY,
  title      TEXT NOT NULL,
  done       BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO tasks (title) VALUES
  ('Lire le cours de virtualisation'),
  ('Faire le TP1 - Vercel et VMs'),
  ('Faire le TP2 - Docker'),
  ('Faire le TP3 - Docker Compose');
