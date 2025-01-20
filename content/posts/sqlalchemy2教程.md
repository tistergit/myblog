---
title: "sqlalchemy2教程"
date: 2025-01-20
draft: false
---

### 查询

```python
stmt = select(WinterTeamInfo).where(WinterTeamInfo.team_id == team_id)
teaminfo = session.scalar(stmt)
```

### 更新

```python
update_stmt = (
                update(WinterRank)
                .where(WinterRank.team_id == team_id, WinterRank.event_id == event_id)
                .values(score=score)
            )
            session.execute(update_stmt)
session.commit()
```

### 插入
```python
ins_stmt = insert(WinterRank).values(
                box_id=box_id,
                box_name=boxinfo.name,
                team_id=team_id,
                team_name=teaminfo.team_name,
                event_id=event_id,
                event_name=eventinfo.event_name_cn,
                score=score,
                timestamp=time.time(),
            )
            session.execute(ins_stmt)
        session.commit()
```

### 关联查询
```python
            stmt = (
                select(WinterRank, WinterTeamInfo)
                .join(WinterTeamInfo, WinterRank.team_id == WinterTeamInfo.team_id)
                .where(WinterRank.event_id == event_id)
                .where(WinterRank.score > 0)
                .order_by(WinterRank.score.asc())
            )
            logger.info(" stmt : %s ", stmt)
            results = session.execute(stmt)
            logger.info("results : %s ", results)
            resp_list = []
            for rank, team in results:
                logger.info("result : %s ", type(rank))
                resp = WinterRankAllResp(
                    team_name=rank.team_name,
                    team_img=team.team_img,
                    event_id=rank.event_id,
                    event_name=rank.event_name,
                    score=int(rank.score),
                    # timestamp=datetime.datetime.fromtimestamp(result.timestamp),
                )
                resp_list.append(resp)
```

### group by 
```python
            stmt = (
                select(
                    WinterRank.team_id,
                    WinterRank.team_name,
                    WinterTeamInfo.team_img,
                    func.sum(WinterRank.score).label("total_score"),
                )
                .join(WinterTeamInfo, WinterRank.team_id == WinterTeamInfo.team_id)
                .group_by(
                    WinterRank.team_id, WinterRank.team_name, WinterTeamInfo.team_img
                )
                .having(func.sum(WinterRank.score) > 0)
                .order_by(asc("total_score"))
            )
            results = session.execute(stmt)
            logger.info("results : %s ", results)
            for t_id, t_name, img, c_s in results:
                logger.info("result : %s , %s , %s  ", t_id, t_name, c_s)
                resp = WinterRankAllResp(
                    team_name=t_name,
                    team_img=img,
                    event_id=event_id,
                    event_name="ALL",
                    score=int(c_s),
                    # timestamp=datetime.datetime.fromtimestamp(result.timestamp),
                )
                resp_list.append(resp)
            return resp_list
```

