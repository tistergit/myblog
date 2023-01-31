---
title: Pandas日常使用技巧
date: 2022-09-18
draft: false
---

## Pandas日常使用技巧

### Pandas与sqlalchemy结合

```python
from sqlalchemy.engine import create_engine
from sqlalchemy.orm.session import sessionmaker
import pandas as pd

SQLALCHEMY_DATABASE_URI = "mysql+pymysql://user:password@host/database"
engine = create_engine(SQLALCHEMY_DATABASE_URI)

DBSession = sessionmaker(bind=engine)
df = pd.read_sql(" select * from t_tickets where  created_time >= '2017-12-1' and created_time <= '2017-12-31' ", engine)
```

### 循环Dataframe
```python

for index, row in df.iterrows():
    que_extend = row['que_extend']
    que_id = row['id']

```

### 在pandas中查询结果，使用sqlalchemy更新数据
```python
SQLALCHEMY_DATABASE_URI = "mysql+pymysql://user:password@host/database"
engine = create_engine(SQLALCHEMY_DATABASE_URI)

DBSession = sessionmaker(bind=engine)

def batch_update(df , cr):
    session = DBSession()
    for index, row in df.iterrows():
        que_extend = row['que_extend']
        que_id = row['id']
        cr.put_org_str(que_extend)
        logging.info("%s || %s || %s || %s || %s " % (que_id  , que_extend.decode("utf8") , cr.recommon0() , cr.recommon1() , cr.recommon2()  ))
        
        ticket = session.query(TicketsTable).filter_by(id=que_id).first()
        ticket.que_group = cr.recommon0()
        ticket.que_platform = cr.recommon1()
        ticket.que_event = cr.recommon2()
        session.add(ticket)
        session.commit()

```