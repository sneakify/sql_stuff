drop database if exists spootify;
create database spootify;
use spootify;
drop table if exists user;
drop table if exists buy;
drop table if exists sell;
drop table if exists top_50;
    
    
 create table artist (
	artist_id int primary key,
    artist_name varchar(75) not null,
    genre varchar(30) not null
    );

insert into artist values
	(1, 'Bob', 'trance');
    
create table album (
	album_id int primary key,
    album_name varchar(75)
    );

insert into album values
	(1, 'album1');
    
create table song(
	spotify_id int primary key,
    title varchar(75) not null,
    artist_id int not null,
    album_id int not null,
    song_rank int not null,
    constraint fk_artist_id_song foreign key(artist_id) references artist(artist_id),
    constraint fk_album_id_song foreign key(album_id) references album(album_id)
    );
    
insert into song values
	(1, 'song1', 1, 1, 100),
    (2, 'song2', 1, 1, 20),
    (3, 'song3', 1, 1, 0);
    
    
    
create table song_history (
	date date not null,
    spotify_id int not null,
    day_value int not null,
    constraint fk_spotify_id_song_history foreign key(spotify_id) references song(spotify_id)
    );

create table user (
	user_id int primary key auto_increment,
    full_name varchar(50) not null,
    user_name varchar(25) unique not null,
    email varchar(255) unique not null,
    password varchar(30) not null,
    created datetime not null,
    purchasing_power int not null
    );

insert into user values
	(1, 'm', 'm', 'm@m.com', 'password', '2019-04-08 03:02:54', 5000),
    (2, 'n', 'n', 'n@n.com', 'password', '2019-04-08 03:02:54', 10);

create table user_history (
	date date not null,
    user_id int not null,
    portfolio_value int not null,
    constraint fk_spotify_id_user_history foreign key(user_id) references user(user_id)
    );
    
create table buy (
	buy_id int primary key,
	user_id int not null,
    spotify_id int not null,
    price int not null,
    n_shares int not null,
    purchase_time datetime not null,
    constraint fk_user_id_buy foreign key(user_id) references user(user_id),
    constraint fk_spotify_id_buy foreign key(spotify_id) references song(spotify_id)
    );
    
insert into buy values
	(1, 1, 1, 100, 5, '2019-04-08 12:02:54'),
    (2, 1, 2, 50, 20, '2019-04-08 12:02:54'),
    (3, 1, 1, 100, 5, '2019-04-08 12:02:54'),
    (4, 2, 2, 50, 1, '2019-04-08 12:02:54');
    
    
create table sell (
	sell_id int primary key,
	user_id int not null,
    spotify_id int not null,
    price int not null,
    n_shares int not null,
    sale_time datetime not null,
    constraint fk_user_id_sell foreign key(user_id) references user(user_id),
    constraint fk_spotfiy_id_sell foreign key(spotify_id) references song(spotify_id)
    );
    
insert into sell values
	(1, 1, 1, 95, 5, '2019-04-08 14:02:54'),
    (2, 1, 2, 50, 10, '2019-04-08 14:02:54');

Select user_id, spotify_id, sum(n_shares) as user_bought
From buy
Group by user_id, spotify_id;

Select user_id, spotify_id, sum(n_shares) as user_sold
From sell
Group by user_id, spotify_id;  





Select user_id, spotify_id, user_bought - coalesce(user_sold,0) as shares_owned
		From 
			(Select user_id, spotify_id, sum(n_shares) as user_bought
			From buy
			Group by user_id, spotify_id) as total_bought
		Left Join 
			(Select user_id, spotify_id, sum(n_shares) as user_sold
			From sell
			Group by user_id, spotify_id) as total_sold
			Using (user_id, spotify_id);


            
-- buying trigger
Drop Trigger If Exists buy_triggers;

Delimiter //

Create Trigger buy_triggers
	Before Insert On buy
    For Each Row
Begin
	If ((New.price * New.n_shares) > user.purchasing_power) Then
		Signal Sqlstate 'HYOOO'
			Set Message_Text = 'Insufficient Funds';
	End If;
    If (time(New.purchase_time) < '9:30' Or time(New.purchase_time) > '16:30') Then
		Signal Sqlstate 'HYOOO'
			Set Message_Text = 'Market Closed';
	Else
		Update user
        Set purchasing_power = purchasing_power - (New.n_shares * New.price)
        Where user.user_id = New.user_id;
	End If;
End //

-- buy trigger testing

-- selling trigger

Delimiter //

-- function that calculates shares of given stock bought by a given user
CREATE FUNCTION shares_bought (u_id INT, s_id INT)
RETURNS INT

BEGIN
DECLARE bought INT;

Select user_id, sum(n_shares) into bought
From buy
Where u_id = user_id And s_id = spotify_id
Group by user_id, spotify_id;

RETURN bought;
END //

Delimiter //

-- function that calculates shares of given stock sold by a given user
CREATE FUNCTION shares_sold (u_id INT, s_id INT)
RETURNS INT

BEGIN
DECLARE sold INT;

Select user_id, sum(n_shares) into sold
From sell
Where u_id = user_id And s_id = spotify_id
Group by user_id, spotify_id;

RETURN sold;
END //


Drop Trigger If Exists sell_triggers;

Delimiter //


-- trigger based of sales being made
Create Trigger sell_triggers
	Before Insert On sell
    For Each Row
Begin
	If (New.n_shares > shares_bought(New.user_id, New.spotify_id) - shares_sold(New.user_id, New.spotify_id)) Then
		Signal Sqlstate 'HYOOO'
			Set Message_Text = 'Not Enough Shares';
	End If;
    If (time(New.sale_time) < '9:30' Or time(New.sale_time) > '16:30') Then
		Signal Sqlstate 'HYOOO'
			Set Message_Text = 'Market Closed';
	Else
		Update user
        Set purchasing_power = purchasing_power + (New.n_shares * New.price)
        Where user.user_id = New.user_id;
	End If;
End //
    

-- resets song value every day
create event reset_song_value
	on schedule every 1 day
	starts '2019-01-01 00:03:00' 
do
	update song
    set date = curdate(),
		day_value = 0;


-- updates song history every day
create event update_song_history
	on schedule every 1 day
	starts '2019-01-01 00:05:00' 
do
	insert into song_history
    select curdate(), spotify_id, song_rank
    from song;

-- updates user history every day
create event update_user_history
	on schedule every 1 day
	starts '2019-01-01 00:09:30'
do
	insert into user_history
    select curdate(), user_id, portfolio_value
    from 
    (Select user_id, (sum(total_value) + purchasing_power) as portfolio_value
		From
		(Select user_id, spotify_id, shares_owned * song_rank as total_value
		From
			(Select user_id, spotify_id, user_bought - coalesce(user_sold,0) as shares_owned
			From 
				(Select user_id, spotify_id, sum(n_shares) as user_bought
				From buy
				Group by user_id, spotify_id) as total_bought
			Left Join 
				(Select user_id, spotify_id, sum(n_shares) as user_sold
				From sell
				Group by user_id, spotify_id) as total_sold
				Using (user_id, spotify_id)) as user_total
		Join song Using (spotify_id)) as user_share_value
	Join user Using (user_id)
	Group by user_id) as daily_portfolio
Where user.user_id = daily_portfolio.user_id;




