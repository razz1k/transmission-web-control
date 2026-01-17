## Внимание: проект больше не поддерживается
> Из-за того, что проект устарел, используемые технологии слишком старые, и у меня больше нет сил для обновления этого проекта, я решил заархивировать проект. Вы можете использовать другие альтернативные проекты.
>
> Если вы все еще хотите использовать этот проект, лучший способ - использовать версию 2.94 в Docker, а затем установить переменную окружения для указания WebUI. Подробности можно найти здесь (https://www.cnblogs.com/ronggang/p/18788723); или использовать другие интегрированные проекты.
>
> Спасибо за долгую поддержку.
> 
> 2025.06.01 栽培者

----

<p align="center">
<img src="https://github.com/ronggang/transmission-web-control/raw/master/src/tr-web-control/logo.png"><br/>
<a href="https://github.com/ronggang/transmission-web-control/releases" title="GitHub Releases"><img src="https://img.shields.io/github/release/ronggang/transmission-web-control.svg"></a>
<img src="https://img.shields.io/badge/transmission-%3E=2.40%20(RPC%20%3E14)-green.svg" title="Support Transmission Version">
<a href="https://github.com/ronggang/transmission-web-control/LICENSE" title="GitHub license"><img src="https://img.shields.io/github/license/ronggang/transmission-web-control.svg"></a>
<a href="https://t.me/transmission_web_control"><img src="https://img.shields.io/badge/Telegram-Chat-blue.svg?logo=telegram" alt="Telegram"/></a>
</p>

----
## [English Introduction](https://github.com/ronggang/transmission-web-control/wiki)

## Зеркало для Китая
- https://gitee.com/culturist/transmission-web-control

## О проекте
Основная цель этого проекта - улучшить возможности управления [Transmission](https://www.transmissionbt.com/) через веб-интерфейс. Проект изначально размещался на [Google Code](https://code.google.com/p/transmission-control/), а теперь перенесен на GitHub.
Проект изначально разрабатывался специально для PT-сайтов, поэтому добавлена группировка и статус серверов Tracker, но это не подходит для обычных BT-торрентов.

Кроме того, этот проект представляет собой только пользовательский веб-интерфейс и не может заменить Transmission. Пользователям необходимо самостоятельно установить Transmission перед использованием. Инструкции по установке Transmission можно найти на официальном сайте: https://www.transmissionbt.com/

## Предварительный просмотр интерфейса
![screenshots](https://user-images.githubusercontent.com/8065899/38598199-0d2e684c-3d8e-11e8-8b21-3cd1f3c7580a.png)

## Методы установки и дополнительная информация, см.: [справка](https://github.com/ronggang/transmission-web-control/wiki/Home-CN) 
### DSM7.0
В этой версии требуется дополнительно изменить права доступа для реализации функции автоматического обновления
Выполните следующие команды с правами `root`, где:
 - `YOUR_USERNAME` замените на пользователя, которого вы выбрали при входе и обновлении скрипта
 - `/var/packages/transmission/target/share/transmission/web/` - это путь установки transmission (по умолчанию должен быть таким)
```shell
sed -i '/sc-transmission/s/$/YOUR_USERNAME/' /etc/group
chown sc-transmission:sc-transmission /var/packages/transmission/target/share/transmission/web/* -R
chmod 774 /var/packages/transmission/target/share/transmission/web/* -R
```

## Журнал изменений [Просмотр](https://github.com/ronggang/transmission-web-control/blob/master/CHANGELOG.md)

## Ежедневное обслуживание проекта
* 栽培者
* DarkAlexWang
