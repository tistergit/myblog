---
title: DevOps开发模式
date: 2022-12-18
draft: false
---
对于一个具有一定规模的开发团队而言，团队 Devops 的建设都是迈向高效开发的必经之路，即便没有达到 Devops 建设的程度，为了团队中开发之间的高效协作，基于版本管理工具来选择团队合理的代码分支开发模式都是非常重要的一环。对于这一问题，业界一般有两种主流模式可以供团队选择，特性分支开发模式和主干开发模式，下面就分别介绍一下这两种模式的思路和流程，以及各自的优劣，最后谈一下个人对于不同规模团队应该如何选择开发模式以及如何落地的看法。


# 特性分支开发模式

特性分支开发模式是指为一个或多个特定的需求 / 缺陷 / 任务，从主干分支上拉出特性代码分支（branch），在其特性代码分支上完成相应的开发（一般会经过增量测试）后，再把它合并（merge）到主干分支准备发布的开发模式。
一般特性分支开发模式中常用的有三种：Git-Flow 模式，Github-Flow 模式和 Gitlab-Flow 模式。

## Git-Flow 模式
标准的 Git-Flow 模式一般会包含以下几种分支：

feature 分支：开发者进行对应功能开发的开发分支。
develop 分支：对开发者开发的功能进行集成的分支。
release 分支：负责版本发布的分支。
hotfix 分支：对线上 bug 进行热修复分支。
master 分支：最新线上代码的基准分支。

![Alt text](/images/devops/image-1.png)

每个特性功能都会有属于自己的分支，即 feature 分支，开发者一般会在对应的 feature 分支上做特性功能的开发，如果开发者需要同时进行两个特性功能的开发，需要创建两个 feature 分支，通过 checkout 命令进行分支切换，来防止开发时两个特性功能相互干扰。
一般会在单个特性功能开发完成后，在对应 feature 分支上进行单独验证，在验证通过后，将验证通过的 feature 分支 merge 到 develop 集成分支上，一般 develop  最初是从 master 主分支上拉取。develop 分支永远保存都是最新未发布版本，所以一般特性功能完成 merge 到 develop 分支后，至少会在 develop 分支上进行一次完整的特性功能测试，发布新版本前，也会在 develop 分支上进行全测试，当 develop 分支全测试通过后，会从 develop 分支上拉出 release 分支进行版本发布，并将 develop 的最新代码 merge 到 master 分支上。
若发生线上紧急 bug ，需要进行热修复时，Git-Flow 模式也提供了两种方法：

当新版本已发布  release 分支代码与 master 上的代码同步时，一般会从 master 分支上拉出 hotfix 的分支，专门用于热修复，修复完成之后，进行测试通过，将 hotfix 代码集成到 develop 分支上，再从 develop 分支拉出新的 release 分支上进行发布，同时也需要将 hotfix 代码同步到 master 分支上，保证主干分支代码的标准性。
若是 release 分支代码未发布时，出现 bug 需要热修复，则可以直接在 release 分支上进行修复，进行测试通过后，将修复后的 release 分支代码同步到 develop 分支上，release 分支依然按预期发布，发布的同时 develop 分支同步到 master 分支上。

因为 Git-Flow 模式可以根据不同场景，不同需求提供相当完备的各种分支组合，基本能适应各类团队开发场景，以至于很长一段时间，人们都认为这就是教科书级的 Git 分支使用方式。但是随着普及的范围扩大，人们也发现了这种模式的一些弊端：

分支特别多，每个分支都有自己的职责，各种组合切换非常复杂，上手成本和管理成本非常高。
合并冲突，feature 分支都需要向 develop 分支合并，如果 feature 分支生命周期很长，就意味着它与 develop 分支的代码差异越大，冲突概率和解决冲突的难度也越高。主干分支同理，如果同时几个长生命周期的 feature 分支向 develop 合并，将是集成的噩梦。
需要较多环境资源，毕竟一个 feature 分支就需要一个测试环境资源，且在开发完成前会一直占用。

## GitHub-Flow 模式
GitHub-Flow 模式相较于 Git-Flow 模式更为简洁，没有了 Git-Flow 模式中 develop ， hoxfix 和 release 分支，对于 GitHub-Flow 模式来说，发布版本应该是持续的，快速的。feature 分支即 develop 分支，master 分支即 release 分支，对于 hotfix 的处理，GitHub-Flow 模式认为本质上也是特性修改，处理方式和 feature 分支理念是一致的。总的来说，所有特性修改都能快速集成到 master 上发布，小步快走，快速迭代。

![Alt text](/images/devops/image-2.png)

GitHub-Flow 模式在特性分支开发模式中最为简洁，持续集成部署的效率最高。因为所有特性修改的内容会频繁的合入 master 中，并频繁进行部署，这意味着可以最小粒度部署特性修改的代码，在当前倡导持续快速交付的环境下，显然这种模式具有很大的优势。但因为没有 release 分支的存在，需要建立完善的 rollback 机制来保障线上服务问题后的快速恢复。

## GitLab-Flow 模式

GitLab-Flow 模式相较于上两种模式，提供了一种比较中和的选择，既不像 GitHub-Flow 模式简单，也不像 Git-Flow 模式臃肿。最大区别是体现发布侧，引入了 Pre-production 和 Production 两种发布分支，分别对应预发布和发布环境，master 则对应的是集成环境。
当一个特性功能在 Feature 分支上开发完成后，提交 merge request 将代码合并到 master 分支上，部署到集成环境上进行验证。当验证通过后，从集成环境的这个节点，拉出预发布环境 pre-production 分支进行预发环境的服务部署，如果团队一直维护了一个预发布环境 pre-production 基线分支，也可以将验证通过后的集成环境 master 代码提交 merge request 合并到 pre-production 分支上进行预发环境的服务部署，两种方式皆可，取决于团队的分支管理方式。同理，按照相同的方式将 pre-production 分支上的代码合并到 production 分支上就可以进行生产环境的部署了。

![Alt text](/images/devops/image-3.png)

GitLab-Flow 模式与 GitHub-Flow 模式还有一个不同是在 merge 的方式上，GitLab-Flow 模式采用的是 merge request 的方式，GitHub-Flow 模式是采用的 pull request 的方式。这两种合并代码方式其实是同一中东西，仅仅是因为 GitLab 和 GitHub 的平台特性，使用了不同的名字，大家不用纠结于采用哪种方式。
业界比较流行的一般就是上面介绍的这三种特性分支开发模式。因为特性分支开发模式的本质是根据不同特性创建不同分支进行组合管理，所以形态非常灵活多变，团队在使用时不必拘泥于固定的模式模版，应该根据团队的需求进行适当的修改适配，才能发挥它的优势。

# 主干开发模式
主干开发模式是指所有的开发人员仅在一个主干分支（master）上进行协作开发，一般不允许新建其他长期存在的开发分支，所有的代码提交均需要在主干分支上完成。通常这种开发模式下，开发者需要有较高频率的代码推送行为，一般一天至少提交一次，当主干分支达到发布条件后，就从主干分支上拉出发布分支（release）进行版本发布。开发或测试过程中发现的代码缺陷也会直接在主干上进行修复，再根据实际需求 cherry pick 到特定的发布分支或是进行新版本发布。

![Alt text](/images/devops/image-4.png)